//
// Copyright 2015 The REST Switch Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, Licensor provides the Work (and each Contributor provides its 
// Contributions) on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied, including, 
// without limitation, any warranties or conditions of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A PARTICULAR 
// PURPOSE. You are solely responsible for determining the appropriateness of using or redistributing the Work and assume any 
// risks associated with Your exercise of permissions under this License.
//
// Author: John Clark (johnc@restswitch.com)
//


#include <ngx_config.h>
#include <ngx_core.h>
#include <ngx_http.h>

#include "auth.h"


typedef struct {
    ngx_http_complex_value_t  *hmac_auth_message;
    ngx_http_complex_value_t  *hmac_auth_secret;
    ngx_http_complex_value_t  *hmac_auth_hash;
} ngx_hmac_auth_conf_t;


static ngx_int_t ngx_hmac_auth_result_handler(ngx_http_request_t *r, ngx_http_variable_value_t *v, uintptr_t data);
static void *ngx_hmac_auth_create_conf(ngx_conf_t *cf);
static char *ngx_hmac_auth_merge_conf(ngx_conf_t *cf, void *parent, void *child);
static ngx_int_t ngx_hmac_auth_add_variables(ngx_conf_t *cf);


static ngx_command_t  ngx_hmac_auth_module_commands[] = {

    { ngx_string("hmac_auth_message"),
      NGX_HTTP_MAIN_CONF|NGX_HTTP_SRV_CONF|NGX_HTTP_LOC_CONF|NGX_CONF_TAKE1,
      ngx_http_set_complex_value_slot,
      NGX_HTTP_LOC_CONF_OFFSET,
      offsetof(ngx_hmac_auth_conf_t, hmac_auth_message),
      NULL },

    { ngx_string("hmac_auth_secret"),
      NGX_HTTP_MAIN_CONF|NGX_HTTP_SRV_CONF|NGX_HTTP_LOC_CONF|NGX_CONF_TAKE1,
      ngx_http_set_complex_value_slot,
      NGX_HTTP_LOC_CONF_OFFSET,
      offsetof(ngx_hmac_auth_conf_t, hmac_auth_secret),
      NULL },

    { ngx_string("hmac_auth_hash"),
      NGX_HTTP_MAIN_CONF|NGX_HTTP_SRV_CONF|NGX_HTTP_LOC_CONF|NGX_CONF_TAKE1,
      ngx_http_set_complex_value_slot,
      NGX_HTTP_LOC_CONF_OFFSET,
      offsetof(ngx_hmac_auth_conf_t, hmac_auth_hash),
      NULL },

      ngx_null_command
};


static ngx_http_variable_t  ngx_hmac_auth_vars[] = {
    { ngx_string("hmac_auth_result"), NULL,
      ngx_hmac_auth_result_handler, 0, NGX_HTTP_VAR_CHANGEABLE, 0 },

    { ngx_null_string, NULL, NULL, 0, 0, 0 }
};


static ngx_http_module_t  ngx_hmac_auth_module_ctx = {
    ngx_hmac_auth_add_variables,     // preconfiguration
    NULL,                            // postconfiguration

    NULL,                            // create main configuration
    NULL,                            // init main configuration

    NULL,                            // create server configuration
    NULL,                            // merge server configuration

    ngx_hmac_auth_create_conf,       // create location configuration
    ngx_hmac_auth_merge_conf         // merge location configuration
};


static ngx_module_t  ngx_hmac_auth_module = {
    NGX_MODULE_V1,
    &ngx_hmac_auth_module_ctx,       // module context
    ngx_hmac_auth_module_commands,   // module directives
    NGX_HTTP_MODULE,                 // module type
    NULL,                            // init master
    NULL,                            // init module
    NULL,                            // init process
    NULL,                            // init thread
    NULL,                            // exit thread
    NULL,                            // exit process
    NULL,                            // exit master
    NGX_MODULE_V1_PADDING
};


static ngx_int_t ngx_hmac_auth_result_handler(ngx_http_request_t *r, ngx_http_variable_value_t *v, uintptr_t data)
{
    ngx_hmac_auth_conf_t    *conf;
    ngx_str_t                message, secret, hash;
    int                      res;

    conf = ngx_http_get_module_loc_conf(r, ngx_hmac_auth_module);
    if (conf->hmac_auth_message == NULL) {
        ngx_log_error(NGX_LOG_ERR, r->connection->log, 0, "ngx_hmac_auth_result_handler: conf->hmac_auth_message not found");
        goto not_found;
    }
    if (conf->hmac_auth_secret == NULL) {
        ngx_log_error(NGX_LOG_ERR, r->connection->log, 0, "ngx_hmac_auth_result_handler: conf->hmac_auth_secret not found");
        goto not_found;
    }
    if (conf->hmac_auth_hash == NULL) {
        ngx_log_error(NGX_LOG_ERR, r->connection->log, 0, "ngx_hmac_auth_result_handler: conf->hmac_auth_hash not found");
        goto not_found;
    }

    // hmac message
    if (ngx_http_complex_value(r, conf->hmac_auth_message, &message) != NGX_OK) {
        ngx_log_error(NGX_LOG_ERR, r->connection->log, 0, "ngx_hmac_auth_result_handler: failed to convert conf->hmac_auth_message to string");
        return(NGX_ERROR);
    }
    ngx_log_error(NGX_LOG_NOTICE, r->connection->log, 0, "ngx_hmac_auth_result_handler: hmac_auth_message: [%V]", &message);

    // hmac secret
    if (ngx_http_complex_value(r, conf->hmac_auth_secret, &secret) != NGX_OK) {
        ngx_log_error(NGX_LOG_ERR, r->connection->log, 0, "ngx_hmac_auth_result_handler: failed to convert conf->hmac_auth_secret to string");
        return(NGX_ERROR);
    }
    ngx_log_error(NGX_LOG_NOTICE, r->connection->log, 0, "ngx_hmac_auth_result_handler: hmac_auth_secret: [%V]", &secret);

    // hmac compare hash
    if (ngx_http_complex_value(r, conf->hmac_auth_hash, &hash) != NGX_OK) {
        ngx_log_error(NGX_LOG_ERR, r->connection->log, 0, "ngx_hmac_auth_result_handler: failed to convert conf->hmac_auth_hash to string");
        return(NGX_ERROR);
    }
    ngx_log_error(NGX_LOG_NOTICE, r->connection->log, 0, "ngx_hmac_auth_result_handler: hmac_auth_hash: [%V]", &hash);

    res = auth_validate_hash((char*)message.data, message.len, 
                             (char*)secret.data, secret.len,
                             (char*)hash.data, hash.len);
    if(res == 0) {
        // success
        ngx_log_error(NGX_LOG_NOTICE, r->connection->log, 0, "ngx_hmac_auth_result_handler: success: message authenticated");
        v->data = (u_char *)"0";
    }
    else {
        // failure
        switch(res) {
            case 1:
                v->data = (u_char *)"1";
                ngx_log_error(NGX_LOG_ERR, r->connection->log, 0, "ngx_hmac_auth_result_handler: auth_validate_hash - hashes dont match");
                break;
            case -1:
                v->data = (u_char *)"2";
                ngx_log_error(NGX_LOG_ERR, r->connection->log, 0, "ngx_hmac_auth_result_handler: auth_validate_hash - invalid hmac_auth_message length (too short)");
                break;
            case -2:
                v->data = (u_char *)"3";
                ngx_log_error(NGX_LOG_ERR, r->connection->log, 0, "ngx_hmac_auth_result_handler: auth_validate_hash - invalid hmac_auth_hash length");
                break;
            case -3:
                v->data = (u_char *)"4";
                ngx_log_error(NGX_LOG_ERR, r->connection->log, 0, "ngx_hmac_auth_result_handler: auth_validate_hash - timestamp could not be decoded");
                break;
            case -4:
                v->data = (u_char *)"5";
                ngx_log_error(NGX_LOG_ERR, r->connection->log, 0, "ngx_hmac_auth_result_handler: auth_validate_hash - request has expired");
                break;
            case -5:
                v->data = (u_char *)"6";
                ngx_log_error(NGX_LOG_ERR, r->connection->log, 0, "ngx_hmac_auth_result_handler: auth_validate_hash - hash generation failed");
                break;
            default:
                v->data = (u_char *)"9";
                ngx_log_error(NGX_LOG_ERR, r->connection->log, 0, "ngx_hmac_auth_result_handler: auth_validate_hash - unknown error: [%d]", res);
                break;
        }
    }

    v->len = 1;
    v->valid = 1;
    v->no_cacheable = 0;
    v->not_found = 0;

    return NGX_OK;

not_found:
    v->not_found = 1;

    return NGX_OK;
}


static void *ngx_hmac_auth_create_conf(ngx_conf_t *cf)
{
    ngx_hmac_auth_conf_t  *conf;

    conf = ngx_pcalloc(cf->pool, sizeof(ngx_hmac_auth_conf_t));
    if (conf == NULL) {
        return NULL;
    }

    // set by ngx_pcalloc():
    //     conf->hmac_auth_message = NULL;
    //     conf->hmac_auth_secret = NULL;
    //     conf->hmac_auth_hash = NULL;

    return conf;
}


static char *ngx_hmac_auth_merge_conf(ngx_conf_t *cf, void *parent, void *child)
{
    ngx_hmac_auth_conf_t *prev = parent;
    ngx_hmac_auth_conf_t *conf = child;

    if (conf->hmac_auth_message == NULL) {
        conf->hmac_auth_message = prev->hmac_auth_message;
    }

    if (conf->hmac_auth_secret == NULL) {
        conf->hmac_auth_secret = prev->hmac_auth_secret;
    }

    if (conf->hmac_auth_hash == NULL) {
        conf->hmac_auth_hash = prev->hmac_auth_hash;
    }

    return NGX_CONF_OK;
}


static ngx_int_t ngx_hmac_auth_add_variables(ngx_conf_t *cf)
{
    ngx_http_variable_t  *var, *v;

    for (v = ngx_hmac_auth_vars; v->name.len; v++) {
        var = ngx_http_add_variable(cf, &v->name, v->flags);
        if (var == NULL) {
            return NGX_ERROR;
        }

        var->get_handler = v->get_handler;
        var->data = v->data;
    }

    return NGX_OK;
}

