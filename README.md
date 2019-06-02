# Intel SGXの小さなサンプル

## はじめに

LinuxでIntel SGXを試してみたい。小さなサンプルコードが見つからなかったので、リファレンスなどを参照しながら最小限のサンプルコードを書いたみたので、その過程をここに残しておく。

Intel SGX Linux 2.3.1リリースでの情報である。

また、Intel SGXには様々な機能があるが、ここではenclave call（ECALL）というもっとも基本的な機能を試すことにする。これはenclaveというIntel SGXによって保護された安全な領域に置かれた関数を呼び出す操作である。

ここではenclaveに（enclave内に安全に保管されている）「hello, enclave」という文字列を与えられた領域にコピーする関数を用意し、これを呼び出すアプリケーションを作成する。実際のアプリケーションではenclaveの中で秘密鍵の生成処理や、それを用いた署名処理などを実装するイメージか。

## 必要なもの

Intel SGXを使ったアプリケーションを構築するには、以下のファイルを用意する必要がある（「Developer Reference」10ページ）。

1. EDLファイル
2. 設定ファイル
3. 署名に用いる鍵
4. アプリケーションとenclaveのソースコード
5. Makefile

以下、順に説明する。

## EDLファイル

ECALLで呼び出す関数を定義する。
詳細は「Developer Reference」の39ページに説明がある。

今回は以下のとおり `hello` 関数を定義する（ `enclave.edl` ）。 ECALLする関数は `trusted` ブロックに書く。ポインタに対しては属性（ `out` 、 `size` ）を指定する（「Developer Reference」43ページ）。 `public` はそれがuntrustedな関数（enclaveの外）から呼ばれることを許すもの（「Developer Reference」61ページ）。

```
enclave {
    trusted {
        public void hello([out, size=n] char *dest, size_t n);
    };
};
```

このファイルからラッパー関数を生成する。これにより `enclave_[tu].[ch]` が生成される。 `*_t.*` はenclaveの中で動くコード向け（trusted）、 `*_u.*` は外側のアプリケーション向け（untrusted）のもの。

```
$ sgx_edger8r enclave.edl
```

## 設定ファイル

Enclaveで実行するコードは電子署名をする必要がある。この署名の際の設定を記載したファイルである。

必須ではないので今回は作成しない（すべて既定値を使用）。
詳細は「Developer Reference」63ページを参照のこと。

## 署名に用いる鍵

PEM形式でRSA、3072ビット、公開指数は3とする（「Developer Reference」20ページ）。
OpenSSLで作成する場合は以下のとおり。

```
$ openssl genrsa -out private.pem -3 3072
```

## Enclaveのコード

Enclaveの中で動作するコードを書く（ `enclave.c` ）。

```
#include <string.h>
#include "enclave_t.h"

static const char str[] = "hello, enclave";

void hello(char *dest, size_t n)
{
    strncpy(dest, str, n);
    dest[n - 1] = '\0';
}
```

## アプリケーションのコード

`main.c` を参照のこと。

`sgx_create_enclave()` でenclaveを作成して　`enclave_u.h` に定義されたラッパー関数を呼び出す。

## ビルド

Eclaveで動くコードは共有ライブラリにし（リンカーに与えるオプションはSDKに含まれるサンプルコードのMakefileを参考にした）、署名を行う（「Developer Reference」15ページ）。 `Makefile` を参照のこと。

Intel SGXを搭載していなくても動くように、ここではシミュレーションモードでビルドしている。

## 実行

```
$ ./main
hello, enclave
```

## 参考文献

- [Intel Software Guard Extensions (Intel SGX) Developer Guide](https://download.01.org/intel-sgx/linux-2.5/docs/Intel_SGX_Developer_Guide.pdf)
- [Intel Software Guard Extensions (Intel SGX) Developer Reference for Linux OS](https://download.01.org/intel-sgx/linux-2.5/docs/Intel_SGX_Developer_Reference_Linux_2.5_Open_Source.pdf)
- [Getting Started with Intel Software Guard Extensions SDK for Microsoft Windows OS](https://software.intel.com/en-us/articles/getting-started-with-sgx-sdk-for-windows)
