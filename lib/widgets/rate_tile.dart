import 'package:flutter/material.dart';

import '../models/rate.dart';

class RateTile extends StatelessWidget {
  final Rate rate;
  final String fromCurrencyCode;

  const RateTile({super.key, required this.rate, required this.fromCurrencyCode});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                rate.currencyCode.isEmpty
                    ? '?'
                    : rate.currencyCode.substring(0, 1),
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rate.currencyCode,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  Text(
                    rate.currencyName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: scheme.outline, fontSize: 13, height: 1.2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '1 $fromCurrencyCode = ${rate.rate} ${rate.currencyCode}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  'Limits: ${rate.minAmount} - ${rate.maxAmount}',
                  style: TextStyle(color: scheme.outline, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
