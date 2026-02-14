class LatpayStatus {
  static Map<String, String> success({
    String description = "",
  }) {
    return {
      "statuscode": "0",
      "statusdesc": description,
      "errorcode": "",
      "errordesc": "",
    };
  }

  static Map<String, String> error({
    required String errorCode,
    required String errorDesc,
  }) {
    return {
      "statuscode": "1",
      "statusdesc": "",
      "errorcode": errorCode,
      "errordesc": errorDesc,
    };
  }
}