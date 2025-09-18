import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyHomePage extends GetView<ReceiptsController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Load on Scroll Example'),
      ),
      body: GetBuilder<ReceiptsController>(
        init: ReceiptsController(),
        builder: (controller) {
          return MyListView(
            scrollController: controller.scrollController,
            items: controller.items,
            loadMoreCallback: controller.loadMoreItems,
          );
        },
      ),
    );
  }
}

class ReceiptsController extends GetxController {
  final ScrollController scrollController = ScrollController();
  final items = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialItems();
    scrollController.addListener(_scrollListener);
  }

  @override
  void onClose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    super.onClose();
  }

  void _scrollListener() {
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      loadMoreItems();
    }
  }

  void _loadInitialItems() {
    items.addAll(List<String>.generate(20, (index) => 'Item $index'));
  }

  void loadMoreItems() {
    // Simulate loading more items
    final moreItems = List<String>.generate(
        10, (index) => 'New Item ${items.length + index}');
    items.addAll(moreItems);
    update();
  }
}

class MyListView extends StatelessWidget {
  final ScrollController scrollController;
  final List<String> items;
  final VoidCallback loadMoreCallback;

  const MyListView({
    Key? key,
    required this.scrollController,
    required this.items,
    required this.loadMoreCallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      itemCount: items.length + 1, // +1 for the loading indicator
      itemBuilder: (context, index) {
        if (index < items.length) {
          return ListTile(
            title: Text(items[index]),
          );
        } else {
          // Loading indicator
          loadMoreCallback();
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}

