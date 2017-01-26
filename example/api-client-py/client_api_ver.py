# coding: utf8

from time import sleep, time as now
import sys
import socket

from thrift.protocol.TBinaryProtocol import TBinaryProtocol
from thrift.transport.TSSLSocket import TSSLSocket
from thrift.transport.TTransport import TBufferedTransport

from qkd_client_api.v1.QkdApiService import Client
from qkd_client_api.v1 import ttypes


def test_different_key_size_get(api_client):
    print "test_different_key_size_get()"
    is_ok = True
    for size in (1, 8, 128, 1024):
        try:
            key = api_client.get_by_length(size)
            print "OK: Got {} bit key from QKD server".format(len(key.key_body)*8)
        except ttypes.QkdClientError as e:
            is_ok = False
            print "Server error on get_by_length(): \n\t", e.error_code, "|", e.message
            continue
        except ttypes.QkdServerError as e:
            is_ok = False
            print "Server error on get_by_length(): \n\t", e.error_code, "|", e.message, "|", e.retry_after
            continue
    return is_ok


def test_key_qid_get_correct(src_client, dst_client):
    print "test_key_qid_get_correct()"
    try:
        src_key = src_client.get_by_length(8)
        print "OK: Got {} bit key from QKD server by length".format(len(src_key.key_body)*8)
    except ttypes.QkdClientError as e:
        print "Server error on get_by_length(): \n\t", e.error_code, "|", e.message
        return False
    except ttypes.QkdServerError as e:
        print "Server error on get_by_length(): \n\t", e.error_code, "|", e.message, "|", e.retry_after
        return False

    try:
        dst_key = dst_client.get_by_id(src_key.key_id)
        print "OK: Got {} bit key from QKD server by QID".format(len(dst_key.key_body)*8)
        return True
    except ttypes.QkdClientError as e:
        print "Server error on get_by_id(): \n\t", e.error_code, "|", e.message
        return False
    except ttypes.QkdServerError as e:
        print "Server error on get_by_id(): \n\t", e.error_code, "|", e.message, "|", e.retry_after
        return False


def test_key_qid_get_non_correct(api_client):
    print "test_key_qid_get_non_correct()"
    try:
        key = api_client.get_by_id(b"incorrect id")
        print "WARN: Got key from QKD server by incorrect id"
        return False
    except ttypes.QkdClientError as e:
        print "OK: No key returned on incorrect qid: ", e.error_code, "|", e.message
        return True
    except ttypes.QkdServerError as e:
        print "Server error on get_by_id(): \n\t", e.error_code, "|", e.message, "|", e.retry_after
        return False


def test_wrong_proto(server_ip, server_port):
    print "test_wrong_proto()"
    socket.setdefaulttimeout(5)
    conn = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    conn.connect((server_ip, server_port))
    conn.settimeout(5)
    conn.send(b"some bytes")
    try:
        data = conn.recv(2048)
        print "Got response: ", data
        return True
    except socket.timeout:
        print "No data received in 5 second"
    finally:
        conn.close()


if __name__ == "__main__":
    _, tx_host, tx_port, rx_host, rx_port, side = sys.argv

    tx_port = int(tx_port)
    rx_port = int(rx_port)

    if side in ("rx", "RX"):
        is_tx = False
    elif side in ("tx", "TX"):
        is_tx = True
    else:
        print "Wrong side provided"
        exit(-1)

    is_ok = True

    print "Connecting to TX QKD server at {}:{}...".format(tx_host, tx_port)
    # Raw sockets are very slow, use buffered transport
    transp_tx = TBufferedTransport(TSSLSocket(tx_host,
                                              tx_port,
                                              validate=False,
                                              certfile='ssl/tx_client.crt',
                                              keyfile='ssl/tx_client.key',
                                              ca_certs='ssl/pair_ca_bundle.crt'))
    client_tx = Client(TBinaryProtocol(transp_tx))
    transp_tx.open()
    print "OK: Connected"

    print "Connecting to RX QKD server at {}:{}...".format(rx_host, rx_port)
    # Raw sockets are very slow, use buffered transport
    transp_rx = TBufferedTransport(TSSLSocket(rx_host,
                                              rx_port,
                                              validate=False,
                                              certfile='ssl/rx_client.crt',
                                              keyfile='ssl/rx_client.key',
                                              ca_certs='ssl/pair_ca_bundle.crt'))
    client_rx = Client(TBinaryProtocol(transp_rx))
    transp_rx.open()
    print "OK: Connected"

    if not is_tx:
        client_tx, client_rx = client_rx, client_tx

    is_ok &= test_different_key_size_get(client_tx)
    is_ok &= test_key_qid_get_correct(client_rx, client_tx)
    is_ok &= test_key_qid_get_non_correct(client_tx)
    is_ok &= test_wrong_proto(tx_host if is_tx else rx_host,
                              tx_port if is_tx else rx_port)

    if is_ok:
        print "PASSED"
    else:
        print "FAILED"
