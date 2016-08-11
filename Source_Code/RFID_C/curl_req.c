#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <curl/curl.h>
#include <curl/easy.h>
#include "curl_req.h"

const char *SSID      = "Tufts_Wireless";
const char *PSK       = ""; 
const char *DBIP      = "130.64.17.0";
const char *LOCALIP   = "";
char *http_data;

///////////////// Hardware assignments //////////////////////
const int greenLED    = 7;
const int redLED      = 6;
const int relayPin    = 4;
const int HELP_BUTTON = 0;

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

void ReqJMN(char *resp, char *RFID, char *req, char *info, char* station)
{
        printf("Starting request...\n");
        char *httpURL = (char *)calloc(128, 1);
        composeURL(httpURL, RFID, req, info, station);

        if (strcmp(req, "5") == 0) {
                execute_photo_post(resp, httpURL, info);
        }
        else execute_curl(resp, httpURL);
        free(httpURL);
}

void composeURL(char *URL, char *RFID, char *req, char *info, char *station)
{
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
}

void execute_curl(char *resp, char *httpURL)
{
        http_data = resp;
        CURL* curl;
        curl_global_init(CURL_GLOBAL_ALL);
        curl = curl_easy_init();
        curl_easy_setopt(curl, CURLOPT_URL, httpURL);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, &writeCallback);
        //curl_easy_setopt(curl, CURLOPT_VERBOSE, 1L); //tell curl to output its progress

        curl_easy_perform(curl);
        curl_easy_cleanup(curl);

        printf("completed request. httpdata: %s\n",http_data);
}
void execute_photo_post(char *resp, char *httpURL, char *info)
{
        http_data = resp;
        CURL* curl;
        char post_field[64];

        strcpy(post_field, "docfile=@/home/media/");
        strcat(post_field, info);

        curl_global_init(CURL_GLOBAL_ALL);
        curl = curl_easy_init();
        curl_easy_setopt(curl, CURLOPT_URL, httpURL);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, &writeCallback);
        curl_easy_setopt(curl, CURLOPT_VERBOSE, 1L); //tell curl to output its progress
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, post_field);

        curl_easy_perform(curl);
        curl_easy_cleanup(curl);

        printf("completed request. httpdata: %s\n",http_data);
}


