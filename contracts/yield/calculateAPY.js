// SPDX MIT License

//Copyright (c) 2022 Blockswap Labs

//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:

//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.

//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require('dotenv').config();
const axios = require('axios')
const { BigNumber } = require('ethers');
const { gql, request } = require('graphql-request');
const { stakehouseUrls } = require('@blockswaplab/stakehouse-sdk/constants');

const STAKEHOUSE_PRATER_HTTP_ENDPOINT = process.env.STAKEHOUSE_PRATER_HTTP_ENDPOINT;

const getBlockDetails = async () => {

    let client = axios.create({
        baseURL: STAKEHOUSE_PRATER_HTTP_ENDPOINT
    });

    let axiosResponse;

    try {
        axiosResponse = await client.get(`/eth/v1/beacon/headers`);
    } catch (e) {
        console.log(e);
        throw new Error('Failed to get response');
    }

    const apiData = axiosResponse.data;

    return apiData;
};

const getBalance = async(blsPublicKey) => {

    let client = axios.create({
        baseURL: STAKEHOUSE_PRATER_HTTP_ENDPOINT
    });

    let axiosResponse;

    try {
        axiosResponse = await client.get(`/eth/v1/beacon/states/finalized/validators/${blsPublicKey}`);
    } catch (e) {
        console.log(e);
        throw new Error('Failed to get response');
    }

    const apiData = axiosResponse.data.data;

    if(!apiData.validator.slashed) {

        const decimal = BigNumber.from('1000000000');
        const activeBalance = BigNumber.from(apiData.balance) / decimal;
        const effectiveBalance = BigNumber.from(apiData.validator.effective_balance) / decimal;
        const ethDiff = activeBalance - effectiveBalance;
        console.log("ethDiff: ", Number(ethDiff));

        const blockDetails = await getBlockDetails();
        const currentSlot = blockDetails.data[0].header.message.slot;
        const currentEpoch = Math.trunc(currentSlot/32);
        const activationEpoch = apiData.validator.activation_epoch;
        const epochDiff = BigNumber.from(currentEpoch) - BigNumber.from(activationEpoch);
        console.log("epochDiff: ", Number(epochDiff));

        const ethPerEpoch = ethDiff / epochDiff;
        console.log("ethPerEpoch: ", Number(ethPerEpoch));

        const epochInYears = BigNumber.from(365 * 24 * 60 / 6.4);
        console.log("epochInYears: ", Number(epochInYears));

        const ethPerYear = ethPerEpoch * epochInYears;
        console.log("ethPerYear: ", Number(ethPerYear));

        console.log("\n\n");

        return { ethPerYear };
    }

    return;
};

const getListOfKnotsInIndex = async (indexNumber) => {

    const lookupQuery = gql`
        query listOfKnots {
            savETHIndex(id: ${indexNumber}) {
                id
                indexOwner
                knots {
                    id
                }
            }
        }
	`;
  
	const response = await request(
	  stakehouseUrls.SUBGRAPH_ENDPOINTS,
	  lookupQuery
	);

    if (!response) {
        throw new Error('Invalid response getting savETHIndexes')
    }

    if(response.savETHIndex.knots === 'undefined' || response.savETHIndex.knots == null || response.savETHIndex.knots.length == 0) {
        return;
    }

    let ethInAnIndex = Number(0);

    for(let i=0; i<response.savETHIndex.knots.length; i++) {
        console.log("blsPublicKey: ", response.savETHIndex.knots[i].id);
        const ethPerYearForAKnot = await getBalance(response.savETHIndex.knots[i].id);
        ethInAnIndex += Number(ethPerYearForAKnot.ethPerYear);
        console.log("ethSum: ", Number(ethInAnIndex));
    }

    const avgEthInTheIndex = ethInAnIndex / BigNumber.from(response.savETHIndex.knots.length);
    console.log("avgEthInTheIndex: ", Number(avgEthInTheIndex));

    const APY = (avgEthInTheIndex / BigNumber.from('32')) * BigNumber.from('100');
    console.log("APY: ", APY);
};

getListOfKnotsInIndex(3);
