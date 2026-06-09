import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../bloc/lookup_bloc.dart';
import '../bloc/lookup_event.dart';
import '../bloc/lookup_state.dart';
import '../widgets/radial_lookup_menu.dart';

class AdminLookupPage extends StatelessWidget {
  const AdminLookupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<LookupBloc>()..add(LoadLookupCategories()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FB),
        appBar: AppBar(
          centerTitle: true,
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, size: 22, color: Color(0xFF006E2F)),
              SizedBox(width: 8),
              Text(
                'Tra cứu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF006E2F),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFF7F9FB).withValues(alpha: 0.8),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: const Color(0xFFDAE4DC).withValues(alpha: 0.5),
            ),
          ),
        ),
        body: Center(
          child: BlocBuilder<LookupBloc, LookupState>(
            builder: (context, state) {
              if (state is LookupInitial || state is LookupCategoriesLoading) {
                return const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006E2F)),
                );
              }
              
              if (state is LookupCategoriesError) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFBA1A1A), size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Lỗi: ${state.message}',
                      style: const TextStyle(color: Color(0xFFBA1A1A)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<LookupBloc>().add(LoadLookupCategories());
                      },
                      child: const Text('Thử lại'),
                    ),
                  ],
                );
              }

              // Extract categories from whatever state we are in
              var categories = [];
              if (state is LookupCategoriesLoaded) {
                categories = state.categories;
              } else if (state is LookupSearchLoading) {
                categories = state.categories;
              } else if (state is LookupSearchLoaded) {
                categories = state.categories;
              } else if (state is LookupSearchError) {
                categories = state.categories;
              }

              if (categories.isEmpty) {
                return const Text('Không có dữ liệu danh mục');
              }

              return RadialLookupMenu(categories: List.from(categories));
            },
          ),
        ),
      ),
    );
  }
}
