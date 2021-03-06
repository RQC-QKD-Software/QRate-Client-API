# Quantum key distribution (QKD) Thrift API

*Русская версия представлена ниже*

This repository contains QKD device client API description with sample Python client.

QKD implements API server, that stores generated quantum key and serves it to clients. Clients are quantum key consumers (at least one consumer on each side).

QKD consists of two paired devices, both generating the same random sequence, called quantum key. Both devices has the same QKD client API. Device-client channel uses Ethernet connection. SSL (TLSv1.2) is used for client authentication and data protection (channel encryption). QKD client API is based on [Apache Thrift RPC-framework][1].

Client protocol description can be found in [doc/client_api.pdf](doc/client_api.pdf). Sample python-based API client can be found in [doc/example][2] directory.

## Requirements

Following usual steps needed to write QKD API client:
- [Apache Thrift][1] client library for used programming language (version 0.10.0 and higher)
- Use SSL(TLSv1.2) implementation (e.g. [OpenSSL](https://www.openssl.org/) 1.0.2 and higher) to establish secure connection to device
- Generate client-side protocol implementation from Thrift API specification file [client.thrift](client.thrift) using generator of version 0.9.3 or higher (see official docs for further instructions [link][1])

## Quick Start

To implement your own QKD client application (key consumer), you need to generate client-side protocol implementation for used programming language. For example, if your language is python, use following command:
```
thrift -out . -gen py:new_style,slots,no_utf8strings,coding=utf8 client_api.thrift
```

For detailed instructions about code generation from Thrift-files see [official docs][1]).

After this, you need to write client code using generated protocol implementation. Client must implement server connection routine. Following Python code implements simple connection with SSL channel and x509 certificate authentication:

```Python
from thrift.protocol.TBinaryProtocol import TBinaryProtocol
from thrift.transport.TSSLSocket import TSSLSocket
from thrift.transport.TTransport import TBufferedTransport

from qkd_client_api.v1.QkdApiService import Client
from qkd_client_api.v1 import ttypes

transp_tx = TBufferedTransport(TSSLSocket(api_host,
                                          api_port,
                                          validate=False,
                                          certfile='ssl/tx_client.crt',
                                          keyfile='ssl/tx_client.key',
                                          ca_certs='ssl/pair_ca_bundle.crt'))

client_tx = Client(TBinaryProtocol(transp_tx))

transp_tx.open()
```

When connection is established, client object can be used to perform API requests. For example, to get new key of 'size' bytes, perform following call:

```Python
key = client_tx.get_by_length(size)
```
to get existing key by QID:

```Python
key = client_tx.get_by_id(key_id)
```

## Sample test client

Simple Python-based client application present in [example/api-client-py][3] directory. This app contains code for requesting new key by length, requesting existing key by it's QID and handling possible errors.

To interact with real or emulated QKD API server, following ssl-related files must be placed in `api-client-py/ssl/` directory:
- `pair_ca_bundle.crt` - Certificate Authority (root or intermediate) certificate. Used to authorize API server.
- `tx_client.crt` и `tx_client.key` - client x509 certificate and private key. Used to establish connections to TX side QKD server.
- `rx_client.crt` и `rx_client.key` - client x509 certificate and private key. Used to establish connections to RX side QKD server.

These files are included in QKD software bundle (package). Also these files can be found in QKD server emulator bundle.

## Known issues

### Protocol error TLSv1.2 on connection

There are two reasons for this error:
- Python Thrift client library of version 0.9.3

    Solution: update Python Thrift client library to version 0.10.0 or higher

- Old OpenSSL library version without TLSv1.2 support

    Solution: update OpenSSL library to version 1.0.2 or higher

### Python unicode decode error

Error occurs if wrong options were provided during Thrift code generation. Make sure you **don't** use option `utf8strings` with generator of version 0.9.3. Make sure you provide option `no_utf8strings` with generator of version 0.10.0.

## QKD emulator

We can provide QKD server emulation bundle for developers, interested in writing client applications for QKD device. Email us: <akf@rqc.ru> (Alexey Fedorov) or <n.pozhar@rqc.ru> (Nikolay Pozhar).


--------------


# Thrift-API для получения квантовых ключей

Thrift-API предназначено для получения квантовых ключей от устройства квантового распределения ключа *QKD*. QKD предназначено для выработки симметричных квантовых ключей на двух сторонах обмена. Эти стороны мы будем называть *Alice (A)/Передатчик (ПРД/tx)* и *Bob (B)/Приемник (ПРМ/rx)*.

> Квантовый ключ - случайная последовательность, выработанная с помощью квантового устройства.

С точки зрения потребителя квантового ключа QKD на каждой стороне представляет собой сервер, предоставляющий API для получения квантовых ключей.
Потребители квантового ключа являются клиентами.

На каждой стороне QKD производит генерацию, накопление и выдачу квантового ключа потребителям. Для потребителя устройство на каждой стороне предоставляет интерфейс для получения квантового ключа. Взаимодействие потребителя с квантовым устройством осуществляется посредством сети Ethernet. Для аутентификации пользователей и защиты канала связи используется протокол SSL(TLSv1.2). Для предоставления квантовых ключей используется [RPC-фреймворк Apache Thrift][1].

Описание клиентского протокола представлено в файле [doc/client_api.pdf](doc/client_api.pdf). Пример клиентского приложения на языке `Python` представлен в папке [doc/example][2].

## Требования

Для создания собственных клиентских приложений для QKD необходимо:
- Установить библиотеки [Apache Thrift][1] не ниже версии 0.10.0 для используемого языка программирования
- Использовать реализацию SSL(TLSv1.2) для подключения к квантовому устройству (например, [OpenSSL](https://www.openssl.org/) начиная с версии 1.0.2)
- Сгенерировать реализацию клиентского протокола из файла с Thrift-описанием [client.thrift](client.thrift), используя генератор версии не ниже 0.9.3 (подробнее про генерацию кода из файлов описаний можно прочитать по [ссылке][1])

## Быстрый старт

Для создания собственных клиентских приложений необходимо сгенерировать реализацию клиентского протокола для используемого языка программирования. Например, для `Python` необходимо выполнить команду:

```
thrift -out . -gen py:new_style,slots,no_utf8strings,coding=utf8 client_api.thrift
```

Подробнее про генерацию кода их файлов описаний можно прочитать по [ссылке][1].

После генерации реализации протокола, необходимо написать код клиента. Клиент подключается с серверу API, используя сгенерированную реализацию протокола:

```Python

from thrift.protocol.TBinaryProtocol import TBinaryProtocol
from thrift.transport.TSSLSocket import TSSLSocket
from thrift.transport.TTransport import TBufferedTransport

from qkd_client_api.v1.QkdApiService import Client
from qkd_client_api.v1 import ttypes

transp_tx = TBufferedTransport(TSSLSocket(api_host,
                                          api_port,
                                          validate=False,
                                          certfile='ssl/tx_client.crt',
                                          keyfile='ssl/tx_client.key',
                                          ca_certs='ssl/pair_ca_bundle.crt'))

client_tx = Client(TBinaryProtocol(transp_tx))

transp_tx.open()
```

После этого объект клиента можно использовать для вызова функций получения ключа, например:

```Python
key = client_tx.get_by_length(size)
```
или

```Python
key = client_tx.get_by_id(key_id)
```

## Тестовый клиент

В папке [example/api-client-py][3] представлен пример клиентского приложения на `Python`. Клиент содержит примеры получения квантовых ключей по длине и по идентификатору, а так же примеры ошибочных запросов.

Для работы тестового клиента с реальными квантовыми устройствами или их эмуляторами необходимо, чтобы в папке `api-client-py/ssl/` располагались файлы:
- `pair_ca_bundle.crt` - сертификат удостоверяющего центра, используемый для проверки подлинности сервера
- `tx_client.crt` и `tx_client.key` - клиентский сертификат и закрытый ключ используемый для аутентификации на сервере квантового устройства на стороне ПРД
- `rx_client.crt` и `rx_client.key` - клиентский сертификат и закрытый ключ используемый для аутентификации на сервере квантового устройства на стороне ПРМ

Эти файлы предоставляются с комплектом программного обеспечения, входящего в поставку QKD, или поставляются вместе с эмулятором.

## Известные проблемы

### Ошибка TLSv1.2 при подключении к серверу

Эта ошибка может возникать по двум причинам:
- При использовании клиентской Python-библиотеки Thrift версии 0.9.3

    В этом случае необходимо обновить клиентскую библиотеку Thrift до версии 0.10.0 или выше

- При использовании старых версии OpenSSL, которые не поддерживают TLSv1.2

    В этом случае необходимо обновить OpenSSL до версии 1.0.2 или выше

### Ошибка декодирования UTF-8 при использовании Python-клиента

Эта ошибка может возникать из-за неправильно сгенерированного клиентского кода по Thrift-описанию. При использовании генератора версии 0.9.3, убедитесь, что Вы **не** указывали опцию `utf8strings`. При использовании генератора версии 0.10.0, убедитесь, что Вы указали опцию `no_utf8strings`.

## Эмулятор QKD

Если вы заинтересованы в написании клиентских приложений для устройства квантового распределения ключа и хотели бы получить эмулятор QKD, напишите письмо на адрес <akf@rqc.ru> (Алексей Федоров) или <n.pozhar@rqc.ru> (Николай Пожар).

[1]: https://thrift.apache.org/
[2]: https://github.com/RQC-QKD-Software/QRate-Client-API/tree/master/example
[3]: https://github.com/RQC-QKD-Software/QRate-Client-API/tree/master/example/api-client-py
