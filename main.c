#include <stdio.h>
#include <sgx_urts.h>
#include "enclave_u.h"

static const char *enclave_file_name = "enclave.signed.so";

int main(int argc, char *argv[])
{
    sgx_status_t status;
    sgx_launch_token_t token = { 0 };
    int updated;
    sgx_enclave_id_t eid;

    status = sgx_create_enclave(enclave_file_name, SGX_DEBUG_FLAG,
            &token, &updated, &eid, NULL);
    if (status != SGX_SUCCESS) {
        fprintf(stderr, "failed to create enclave: %#x\n", status);
        return 1;
    }

    const size_t n = 32;
    char buf[n];
    status = hello(eid, buf, n);
    if (status != SGX_SUCCESS) {
        fprintf(stderr, "failed to invoke hello(): %#x\n", status);
        return 1;
    }
    puts(buf);

    status = sgx_destroy_enclave(eid);
    if (status != SGX_SUCCESS) {
        fprintf(stderr, "failed to destroy enclave: %#x\n", status);
        return 1;
    }

    return 0;
}
