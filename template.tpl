// Require the necessary APIs
const logToConsole = require('logToConsole');
const injectScript = require('injectScript');
const queryPermission = require('queryPermission');
const setDefaultConsentState = require('setDefaultConsentState');
const updateConsentState = require('updateConsentState');
const callInWindow = require('callInWindow');
const access_consent = require('addConsentListener');
const gtagSet = require('gtagSet');
const getUrl = require('getUrl');
const JSON = require('JSON');
const localStorage = require('localStorage');  // Integrated the local storage API

const LOCALSTORAGE_ITEM_NAME = 'cookiefirst-consent';

// Get the API key the user input into the text field
const apiKey = data.apiKey;
if (!apiKey) {
    logToConsole('No API key provided.');
   
}

const urlPassThrough = !!data.urlPassThrough;
const adsDataRedaction = !!data.adsDataRedaction;
const regionConfig = data.regionConfig || [];
const wait_for_update = data.wait_for_update;
let isDefaultStateFilled = false;

const getRegionArr = (regionStr) => {
    return regionStr.split(',')
        .map(region => region.trim())
        .filter(region => region.length !== 0);
};

const getConsentRegionData = (regionObject) => {
    const consentRegionData = {
        ad_storage: regionObject.advertisingConsent,
        ad_user_data: regionObject.advertisingConsent,
        ad_personalization: regionObject.advertisingConsent,
        analytics_storage: regionObject.performanceConsent,
        functionality_storage: regionObject.functionalConsent,
        personalization_storage: regionObject.functionalConsent,
        security_storage: 'granted'
    };

    const regionArr = getRegionArr(regionObject.region);
    if (regionArr.length) {
        consentRegionData.region = regionArr;
    }
    return consentRegionData;
};

let host;
if (queryPermission('get_url', 'host')) {
    host = getUrl('host');
    if (host.indexOf('www.') === 0) {
        host = host.substring(4);
    }
}

if (!host) {
    logToConsole('No host URL provided.');
    data.gtmOnFailure();
    return;
}

const url = 'https://consent.cookiefirst.com/sites/' + host + '-' + apiKey + '/consent.js';
logToConsole(url);

const onSuccess = () => {
    data.gtmOnSuccess();
};

const onFailure = () => {
    data.gtmOnFailure();
};

const processConsentObject = (consentObject) => {
    const consentModeStates = {
        ad_storage: consentObject.advertising ? 'granted' : 'denied',
        ad_user_data: consentObject.advertising ? 'granted' : 'denied',
        ad_personalization: consentObject.advertising ? 'granted' : 'denied',
        analytics_storage: consentObject.performance ? 'granted' : 'denied',
        functionality_storage: consentObject.functional ? 'granted' : 'denied',
        personalization_storage: consentObject.functional ? 'granted' : 'denied',
        security_storage: 'granted'
    };
    logToConsole('consentModeStates: ', consentModeStates);
    updateConsentState(consentModeStates);
};

const main = (data) => {
    gtagSet({
        'developer_id.dNjAwYj': true,
        url_passthrough: urlPassThrough,
        ads_data_redaction: adsDataRedaction,
    });

    regionConfig.forEach(regionObj => {
        const consentRegionData = getConsentRegionData(regionObj);
        if (wait_for_update > 0) {
            consentRegionData.wait_for_update = wait_for_update;
        }
        setDefaultConsentState(consentRegionData);
        if (regionObj.region === undefined || regionObj.region.trim() === '') {
            isDefaultStateFilled = true;
        }
    });

    if (!isDefaultStateFilled) {
        const defaultState = {
            ad_storage: 'denied',
            ad_user_data: 'denied',
            ad_personalization: 'denied',
            analytics_storage: 'denied',
            functionality_storage: 'denied',
            personalization_storage: 'denied',
            security_storage: 'granted'
        };
        if (wait_for_update > 0) {
            defaultState.wait_for_update = wait_for_update;
        }
        setDefaultConsentState(defaultState);
    }

    // Fetch the consent data from local storage
    if (queryPermission('access_local_storage', 'read', LOCALSTORAGE_ITEM_NAME)) {
        const localStorageConsent = localStorage.getItem(LOCALSTORAGE_ITEM_NAME);
        if (typeof localStorageConsent !=='undefined') {
            logToConsole('Local storage values: ', localStorageConsent);
            const consentObject = JSON.parse(localStorageConsent);
            processConsentObject(consentObject);
        }
    } else {
        logToConsole('No permission to read from local storage.');
    }

  // If the URL input by the user matches the permissions set for the template,
// inject the script with the onSuccess and onFailure methods as callbacks.
 
if (!apiKey) {
    logToConsole('No API key provided, so do not load the consent.js file');
   
} else {  
if (queryPermission('inject_script', url)) {
  injectScript(url, onSuccess, onFailure);
} else {
  logToConsole('Template: Script load failed due to permissions mismatch.');
}
}
  /**
   * Add event listener to trigger update when consent changes
   */
  callInWindow('addCFGTMConsentListener', processConsentObject);
};

main(data);
logToConsole(data);
data.gtmOnSuccess();
