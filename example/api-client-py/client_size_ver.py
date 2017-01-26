# coding: utf8

from time import sleep, time as now
import sys

from thrift.protocol.TBinaryProtocol import TBinaryProtocol
from thrift.transport.TSSLSocket import TSSLSocket
from thrift.transport.TTransport import TBufferedTransport

from qkd_client_api.v1.QkdApiService import Client
from qkd_client_api.v1 import ttypes


if __name__ == "__main__":
    _, api_host, api_port = sys.argv

    api_port = int(api_port)

    print "Connecting to QKD server at {}:{}...".format(api_host, api_port)

    # Raw sockets are very slow, use buffered transport
    transp_tx = TBufferedTransport(TSSLSocket(api_host,
                                              api_port,
                                              validate=False,
                                              certfile='ssl/tx_client.crt',
                                              keyfile='ssl/tx_client.key',
                                              ca_certs='ssl/pair_ca_bundle.crt'))

    client_tx = Client(TBinaryProtocol(transp_tx))

    transp_tx.open()

    print "Connected"

    start_time = now()

    total_key_size = 0
    i = 0
    while 1:
        try:
            key_tx = client_tx.get_by_length(65536/8)
            print "Got 64k key from QKD server"
        except ttypes.QkdClientError as e:
            print "Server error on get_by_length(): \n\t", e.error_code, "|", e.message
            print "FAILED"
            exit(-1)
        except ttypes.QkdServerError as e:
            print "Server error on get_by_length(): \n\t", e.error_code, "|", e.message, "|", e.retry_after
            print "FAILED"
            exit(-1)
        total_key_size += 65536
        i += 1
        if i >= 5:
            break
        sleep(5)

    spent_time = now() - start_time
    avg_speed = float(total_key_size)/spent_time

    print "Got {} bit key in {} seconds, total speed = {} bit/sec".format(total_key_size, spent_time, avg_speed)

    if avg_speed < 10240:
        print "WARN: Key generation too slow"
        print "FAILED"
        exit(-1)

    print "PASSED"
