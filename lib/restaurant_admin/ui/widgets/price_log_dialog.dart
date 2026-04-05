import 'package:flutter/material.dart';

import '../../domain/entities/price_log.dart';
import '../../../utils/i18n.dart';

/// حوار يعرض سجل تغييرات الأسعار لصنف معين.
class PriceLogDialog extends StatelessWidget {
  const PriceLogDialog({super.key, required this.logs, required this.itemName});

  final List<PriceLog> logs;
  final String itemName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${t(context, 'Price Log', 'История цен')} - $itemName'),
      content: SizedBox(
        width: 400,
        child: logs.isEmpty
            ? Text(
                t(
                  context,
                  'No price changes recorded.',
                  'Нет записанных изменений цен.',
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return ListTile(
                    title: Text(
                        '${t(context, 'From', 'С')} ${log.oldPrice.toStringAsFixed(2)} RUB ${t(context, 'to', 'до')} ${log.newPrice.toStringAsFixed(2)} RUB'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${t(context, 'Date', 'Дата')}: ${log.changedAt}',
                        ),
                        if (log.note != null && log.note!.isNotEmpty)
                          Text(
                            '${t(context, 'Note', 'Примечание')}: ${log.note}',
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t(context, 'Close', 'Закрыть')),
        ),
      ],
    );
  }
}
