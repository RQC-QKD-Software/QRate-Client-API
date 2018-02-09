/**
 * <br/><b><i>Quantum key distribution Thrift API.</b></i><br/></br>
 *
 * <i>Русская версия представлена ниже.</i></br></br>
 *
 * Quantum key API of device consists of two functions: get new quantum key and
 * it's unique QID from device by length and get existing (already requested on
 * paired device) key by it's QID.</br></br>
 *
 * <b>Quantum key use routine.</b></br>
 *
 * QKD pair consists of two paired devices. We'll call one side as "A" and other
 * one as "B".</br>
 * 1. <i>Side "A"</i></br>
 *   a. Key consumer on side "A" requests new quantum key from device
 *      (on side A) providing length of new key.</br>
 *   b. Device on side "A" responds with new quantum key and corresponding QID
 *      for this key.</br>
 * 2. <i>Transmission from side "A" to side "B"</i></br>
 *   a. Key consumer on side "A" sends QID to key consumer on side "B".</br>
 * 3. <i>Side "B"</i></br>
 *   a. Key consumer on side "B" requests existing quantum key from device (on
 *      side B) providing QID received from side "A".</br>
 *   b. Device on side "B" responds with same quantum key as device on side "A"
 *      (for given QID).</br></br>
 *
 * Device behaviour on side "A" and side "B" is absolutely same for key
 * consumers.</br></br>
 *
 * API server needs SSL (TLSv1.2) socket to be used for client connections.
 * Client must provide X509 certificate for authentication.<br/><br/>
 *
 * Binary serialization protocol is used for Thrift cobnnections.<br/><br/>
 *
 * API versioning implemented by thrift's namespaces.
 * Backward-compatible API versions use the same namespaces.<br/>
 *
 *
 * <br/></br>------------------<br/></br>
 *
 *
 * <br/><b><i>Thrift-api для получения квантовых ключей.</b></i><br/></br>
 *
 * API включает в себя две функции для получения квантовых ключей от API-сервера
 * (квантового устройства): получение по длине и получение по идентификатору
 * (квиду).</br></br>
 *
 * <b>Последовательность действий по получению и использованию одного ключа.</b>
 * </br>
 *
 * Назовем одну из сторон канала передачи данных "A", другую – "Б".</br>
 * 1. <i>Сторона «А»</i></br>
 *   a. Потребитель на стороне «А» запрашивает квантовый ключ требуемой ему
 *      длины у квантового устройства на своей стороне.</br>
 *   b. Квантовое устройство на стороне «A» возвращает потребителю квантовый
 *      ключ требуемой длины вместе с идентификатором (квидом) этого ключа.</br>
 * 2. <i>Передача от «А» к «Б»</i></br>
 *   a. Потребитель на стороне «A» передает квид потребителю на стороне «Б».
 *      </br>
 * 3. <i>Сторона «Б»</i></br>
 *   a. Потребитель стороне «Б», получив квид ключа, запрашивает у квантового
 *      устройства на своей стороне квантовый ключ, соответствующий полученному
 *      от «А» квид-у.</br>
 *   b. Квантовое устройство на стороне "Б" возвращает тот же ключ, что был
 *      возвращен (с указанным квид-ом) на стороне "A".</br></br>
 *
 * С точки зрения поребителя сторона "А" и сторона "Б" ничем не отличаются и
 * предоставляют одинаковый интерфейс.</br></br>
 *
 * Для подключения к серверу API необходимо использовать SSL (TLSv1.2) сокет
 * с обязательной передачей клиентского X509 сертификата.<br/><br/>
 *
 * Используется Binary протокол сериализации.<br/><br/>
 *
 * Версионирование при сохранении обратной совместимости не требуется
 * (добавление полей и т.д.). Несовместимые версии API используют другой
 * namespace (или его аналог в целевом языке).<br/>
 */

namespace cpp  qkd_client_api.v1
namespace d    qkd_client_api.v1
namespace java qkd_client_api.v1
namespace php  qkd_client_api.v1
namespace perl qkd_client_api.v1
namespace py   qkd_client_api.v1


/**
 * Key data structure. Returned for all key requests.
 * Структура информации о ключе, возвращается при всех запросах на получение
 * ключа.
 */
struct KeyInfo
{
    /**
     * Key body, always present.
     * Тело ключа, возвращается всегда.
     */
    1: binary key_body,

    /**
     * Key identifier, filled on get_by_length() calls, 16 bytes.
     * Must be used for calling get_by_id() on paired device.
     * Идентификатор ключа, возвращается при вызове get_by_length(), 16 байт.
     * Используется для последующего получения этого ключа на принимающей
     * стороне.
     */
    2: binary key_id,

    /**
     * Key lifetime, filled on get_by_length() calls.
     * UNIX timestamp in millis, UTC+0 timezone.
     * Время действия ключа, возвращается при вызове get_by_length().
     * Представлено как UNIX timestamp в миллисекундах в зоне UTC+0.
     */
    3: i64 expiration_time
}


/**
 * Server side error codes (ServerError).
 * Коды серверных ошибок (ServerError).
 */
enum SERVER_ERROR_CODE
{
    /**
     * Server busy or overloaded. Retry later.
     * Сервер занят или перегружен, необходимо повторить запрос позднее.
     */
    ERROR_BUSY = -1,

    /**
     * Insufficient key data on server for processing key request. Retry later.
     * Недостаточно накопленного ключа на сервере, необходимо повторить запрос
     * позднее.
     */
    ERROR_KEY_EXHAUSTED = -2,

    /**
     * Internal server error.
     * Внутренняя ошибка сервера.
     */
    ERROR_INTERNAL = -99
}


/**
 * Client side error codes (ClientError).
 * Коды клиентских ошибок (ClientError).
 */
enum CLIENT_ERROR_CODE
{
    /**
     * Wrong QID provided (non-existent, already used or expired).
     * Указан неверный идентификатор ключа (несуществующий, использованный или
     * истёкший).
     */
    ERROR_KEY_UNKNOWN = -101,

    /**
     * Invalid parameter value (usually key length).
     * Указано недопустимое значение параметра.
     */
    ERROR_INVALID_ARGUMENT = -102
}


/**
 * Server side error, can't be fixed by client.
 * Client must wait for retry_after seconds and retry the same request.
 * Ошибка на стороне сервера, клиент не может на неё повлиять.
 * Можно подождать retry_after секунд и повторить запрос.
 */
exception ServerError
{
    /**
     * Error code.
     * Код ошибки.
     */
    1: i32    error_code,

    /**
     * Time amount before retrying request. This field is always approximate
     * and does not guarantee the presence of a key. It can take values
     * from 1.0 to 300.0. QKD clients can ignore this value and always execute
     * queries with a fixed delay.
     * Время, через которое можно повторить запрос. Это поле всегда имеет
     * приблизительное значение и не гарантирует наличие ключа. Может принимать
     * значения от 1.0 до 300.0. Клиенты QKD могут игнорировать это значение и
     * всегда выполнять запросы с фиксированной задержкой.
     */
    2: double retry_after,

    /**
     * Error description.
     * Текстовое описание ошибки.
     */
    3: string message
}


/**
 * Client side error (wrong request). Retrying with same request will cause
 * same error.
 * Ошибка на стороне клиента. Повторный запрос приведет к этой же ошибке.
 */
exception ClientError
{
    /**
     * Error code.
     * Код ошибки.
     */
    1: i32    error_code,

    /**
     * Error description.
     * Текстовое описание ошибки.
     */
    2: string message
}

service ClientApiService {
    /**
     * Get new key and it's QID for given key length.
     * Получить новый ключ указанной длины и его идентификатор.
     */
    KeyInfo get_by_length(
        /**
         * Key length in bytes.
         * Длина запрашиваемого ключа в байтах.
         */
        1: i32 key_length
    ) throws (
        1: ServerError se,
        2: ClientError ce
    ),

    /**
     * Get existing key by it's QID.
     * Получить существующий ключ по его идентификатору.
     */
    KeyInfo get_by_id(
        /**
         * Key identifier (QID, 16 bytes). Value determined in KeyInfo
         * structure, returned for get_by_length() request.
         * Идентификатор ключа (квид, 16 байт), указанный в структуре KeyInfo
         * при получении.
         */
        1: binary key_id
    ) throws (
        1: ServerError se,
        2: ClientError ce
    )
}
