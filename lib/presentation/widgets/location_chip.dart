import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/address.dart';
import '../viewmodels/language_viewmodel.dart';

class LocationChip extends StatelessWidget {
  final Address? address;
  final VoidCallback? onTap;
  const LocationChip({super.key, this.address, this.onTap});

  @override
  Widget build(BuildContext context) {
    final langVM = Provider.of<LanguageViewModel>(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 255, 255, 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on,
                size: 24, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            if (address != null)
              Flexible(
                child: Text(
                  '${address!.neighborhood}/${address!.district}',
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              Text(
                langVM.translate('unknown'),
                style: const TextStyle(color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
