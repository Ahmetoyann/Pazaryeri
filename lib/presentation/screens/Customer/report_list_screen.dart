import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/home_viewmodel.dart';
import 'report_form_screen.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../widgets/custom_app_bar.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final langVM = context.watch<LanguageViewModel>();
    // Pazarları isme göre alfabetik sırala
    var markets = List.of(vm.nearbyMarkets)
      ..sort((a, b) => a.name.compareTo(b.name));

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      markets = markets.where((m) {
        return m.name.toLowerCase().contains(query) ||
            m.address.neighborhood.toLowerCase().contains(query);
      }).toList();
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(title: Text(langVM.translate('report_tab'))),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 110, 12, 12),
        child: Column(
          children: [
            // Arama Çubuğu
            TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: langVM.translate('search_placeholder'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            // Liste
            Expanded(
              child: markets.isEmpty
                  ? Center(
                      child: vm.state == ViewState.busy
                          ? const CircularProgressIndicator()
                          : Text(langVM.translate('no_results')),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: markets.length,
                      itemBuilder: (c, i) {
                        final m = markets[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.storefront,
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                            title: Text(m.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(m.address.neighborhood),
                            trailing: const Icon(Icons.arrow_forward_ios,
                                size: 16, color: Colors.grey),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ReportFormScreen(market: m),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
