import 'package:flutter/material.dart';

enum InsuranceStatus {
  notInsured,
  requestSubmitted,
  offerGenerated,
  offerAccepted,
  pendingPayment,
  paymentSubmitted,
  active,
  expired
}

extension InsuranceStatusExtension on InsuranceStatus {
  String get name {
    return toString().split('.').last;
  }

  String get displayName {
    switch (this) {
      case InsuranceStatus.notInsured:
        return 'Not Insured';
      case InsuranceStatus.requestSubmitted:
        return 'Request Submitted';
      case InsuranceStatus.offerGenerated:
        return 'Offers Available';
      case InsuranceStatus.offerAccepted:
        return 'Offer Selected';
      case InsuranceStatus.pendingPayment:
        return 'Payment Required';
      case InsuranceStatus.paymentSubmitted:
        return 'Payment Under Review';
      case InsuranceStatus.active:
        return 'Active';
      case InsuranceStatus.expired:
        return 'Expired';
    }
  }

  String get progressMessage {
    switch (this) {
      case InsuranceStatus.notInsured:
        return 'No active insurance';
      case InsuranceStatus.requestSubmitted:
        return 'Request submitted - Waiting for admin review';
      case InsuranceStatus.offerGenerated:
        return 'Insurance offers available - Please select an offer';
      case InsuranceStatus.offerAccepted:
        return 'Offer selected - Waiting for admin approval';
      case InsuranceStatus.pendingPayment:
        return 'Payment required to activate insurance';
      case InsuranceStatus.paymentSubmitted:
        return 'Payment submitted - Waiting for verification';
      case InsuranceStatus.active:
        return 'Insurance policy is active';
      case InsuranceStatus.expired:
        return 'Insurance policy has expired';
    }
  }

  Color get statusColor {
    switch (this) {
      case InsuranceStatus.notInsured:
        return Colors.grey;
      case InsuranceStatus.requestSubmitted:
        return Colors.blue;
      case InsuranceStatus.offerGenerated:
        return Colors.orange;
      case InsuranceStatus.offerAccepted:
        return Colors.lightBlue;
      case InsuranceStatus.pendingPayment:
        return Colors.amber;
      case InsuranceStatus.paymentSubmitted:
        return Colors.purple;
      case InsuranceStatus.active:
        return Colors.green;
      case InsuranceStatus.expired:
        return Colors.red;
    }
  }
}