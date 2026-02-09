  import 'package:rccg_sunday_school/utils/store_links.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> rateApp() async {
    final url = Uri.parse(StoreLinks.review);
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url, 
        mode: LaunchMode.externalApplication,
      );
    }
  }