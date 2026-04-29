import 'package:flutter/services.dart';
import 'package:foap/helper/imports/common_import.dart';

class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String assetPath;

  const LegalDocumentScreen(
      {super.key, required this.title, required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColorConstants.backgroundColor,
      body: Column(
        children: [
          backNavigationBar(title: title),
          Expanded(
            child: FutureBuilder<String>(
              future: rootBundle.loadString(assetPath),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(
                    child: BodyLargeText(
                      errorMessageString.tr,
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.all(DesignConstants.horizontalPadding),
                  child: SelectableText(
                    snapshot.data!,
                    style: TextStyle(
                      color: AppColorConstants.mainTextColor,
                      fontSize: FontSizes.b4,
                      height: 1.5,
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
