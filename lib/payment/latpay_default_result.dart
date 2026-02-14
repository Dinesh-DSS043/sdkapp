class LatpayDefaultResult {
  static Map<String, dynamic> captureError({
    required String errorCode,
    required String errorDesc,
  }) {
    return {
      "Capture": {
        "cardtoken": "",
        "status": {
          "responsetype": "0",
          "statuscode": "1",
          "errorcode": errorCode,
          "errordesc": errorDesc,
        },
        "amount": "",
        "reference": "",
        "description": "",
        "currency": "",
        "cardexpiry": "",
        "cardtype": "",
        "cardlast4": "",
        "cardbin": "",
        "cardholdername": "",
        "surcharge": "",
      }
    };
  }
}