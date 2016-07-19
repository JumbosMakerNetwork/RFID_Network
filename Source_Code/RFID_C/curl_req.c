#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <curl/curl.h>
#include <curl/easy.h>
#include "curl_req.h"

const char *SSID      = "tuftswireless";
const char *PSK       = ""; 
const char *DBIP      = "130.64.17.0";
char *http_data;

///////////////// Hardware assignments //////////////////////
const int greenLED    = 7;
const int redLED      = 6;
const int relayPin    = 4;
const int HELP_BUTTON = 0; //todo assign new pin?

size_t writeCallback(char* buf, size_t size, size_t nmemb, void* up)
{ 
        (void)up;
        //*http_data = "\0";
        /*for (int c = 0; c<size*nmemb; c++) {
                strcat(http_data, buf[c]);
        }*/
        strcpy(http_data, buf);
        return size*nmemb; //tell curl how many bytes we handled
}

char *composeURL(char *RFID, char *req, char *info, char *station)
{
        char *URL = (char *)calloc(128, 1);
        strcpy(URL, "http://");
        strcat(URL, DBIP);
        strcat(URL, ":8000/RFID/");
        strcat(URL, req);
        strcat(URL, "/");
        strcat(URL, station);
        strcat(URL, "/");
        strcat(URL, RFID);
        strcat(URL, "/");
        strcat(URL, info);
        strcat(URL, "/\0");
        printf("URL: %s\n",URL);
        return URL;
}

void ReqJMN(char *resp, char *RFID, char *req, char *info, char* station)
{
        http_data = resp;
        printf("Starting request...\n");
        char *httpURL = composeURL(RFID, req, info, station);
        
        CURL* curl;
        curl_global_init(CURL_GLOBAL_ALL);
        curl = curl_easy_init();
        curl_easy_setopt(curl, CURLOPT_URL, httpURL);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, &writeCallback);
        //curl_easy_setopt(curl, CURLOPT_VERBOSE, 1L); //tell curl to output its progress

        curl_easy_perform(curl);
        curl_easy_cleanup(curl);
        free(httpURL);

        //here parse data, return 't' or 'e' or 'f'
        printf("completed request. httpdata: %s\n",http_data);
}
