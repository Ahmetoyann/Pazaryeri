import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/viewmodels/home_viewmodel.dart';
import 'report_form_screen.dart';
import '../viewmodels/language_viewmodel.dart';
import '../widgets/custom_app_bar.dart';

class ReportListScreen extends StatelessWidget {
  const ReportListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final langVM = context.watch<LanguageViewModel>();
    // Pazarları isme göre alfabetik sırala
    final markets = List.of(vm.nearbyMarkets)
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(title: Text(langVM.translate('report_tab'))),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 110, 12, 12),
        child: markets.isEmpty
            ? Center(
                child: vm.state == ViewState.busy
                    ? const CircularProgressIndicator()
                    : const Text('Pazar bulunamadı'),
              )
            : ListView.separated(
                itemCount: markets.length,
                separatorBuilder: (c, i) => const Divider(),
                itemBuilder: (c, i) {
                  final m = markets[i];
                  return ListTile(
                    title: Text(m.name),
                    subtitle: Text(m.address.neighborhood),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReportFormScreen(market: m),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
