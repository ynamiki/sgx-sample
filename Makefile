SGXSDK = /opt/intel/sgxsdk
CPPFLAGS = -I$(SGXSDK)/include
LDFLAGS = -L$(SGXSDK)/lib64

all: main enclave.signed.so

main: main.o enclave_u.o
	$(CC) $(LDFLAGS) $^ -lsgx_urts_sim -o $@

enclave.signed.so: enclave.so private.pem
	sgx_sign sign -enclave $< -out $@ -key private.pem

private.pem:
	openssl genrsa -out $@ -3 3072

enclave.so: enclave.o enclave_t.o
	$(CC) $(LDFLAGS) $^ \
		-Wl,--no-undefined -nostdlib -nodefaultlibs -nostartfiles \
		-Wl,--whole-archive -lsgx_trts_sim -Wl,--no-whole-archive \
		-Wl,--start-group -lsgx_tstdc -lsgx_tcrypto -lsgx_tservice_sim -Wl,--end-group \
		-Wl,-Bstatic -Wl,-Bsymbolic -Wl,--no-undefined \
		-Wl,-pie,-eenclave_entry -Wl,--export-dynamic \
		-Wl,--defsym,__ImageBase=0 \
		-o $@

enclave_t.o: enclave_t.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -I$(SGXSDK)/include/tlibc -c $<

enclave_t.c enclave_t.h enclave_u.c enclave_u.h: enclave.edl
	sgx_edger8r $<

clean:
	rm -f main enclave.signed.so enclave.so *.o enclave_[tu].[ch]
