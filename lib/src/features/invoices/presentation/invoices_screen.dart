import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/commom/widgets/custom_app_bar.dart';

import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/helpers/media_query_values.dart';
import 'cubit/invoices_cubit.dart';
import 'widgets/invoices_list_view.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  bool _showSearchField = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "mesOperations".tr(context),
        action: !_showSearchField ? FontAwesomeIcons.search : null,
        onTap: () {
          setState(() {
            _showSearchField = true;
          });
        },
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.all(24.sp),
          width: context.width,
          child: Column(
            children: [
              if (_showSearchField)
                Column(
                  children: [
                    SearchBar(),
                    SizedBox(height: 16.sp),
                  ],
                ),
              // ------------- Invoices List View
              const Expanded(child: InvoicesListView())
            ],
          ),
        ),
      ),
    );
  }
}

class SearchBar extends StatefulWidget {
  SearchBar({super.key});

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InvoicesCubit>();

    return SizedBox(
      height: 52.sp,
      child: TextFormField(
        focusNode: _focusNode,
        onFieldSubmitted: (value) {
          _focusNode.requestFocus();
        },
        controller: _searchController,
        onChanged: (value) {
          if (_debounce?.isActive ?? false) _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 300), () {
            if (value.isNotEmpty) {
              cubit.searchInvoices(value);
            } else {
              cubit.getInvoices(isFirstTime: true);
            }
          });
        },
        decoration: InputDecoration(
          prefixIcon: Icon(
            FontAwesomeIcons.search,
            size: 16.sp,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              FontAwesomeIcons.timesCircle,
              size: 16.sp,
            ),
            // Clear icon
            onPressed: () {
              if (_searchController.text != '') {
                _searchController.clear();
                cubit.getInvoices(isFirstTime: true);
              }
            },
          ),
          hintText: "search".tr(context),
          hintStyle: TextStyle(fontSize: 14.sp),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.sp),
          ),
        ),
      ),
    );
  }
}
