import 'package:flutter/material.dart';
import 'package:uae_ecom_project/core/localization/app_translations.dart';
import 'package:url_launcher/url_launcher.dart';

class BulkOrderCard extends StatelessWidget {
  final String productName;

  const BulkOrderCard({super.key, required this.productName});

  Future<void> _launchWhatsApp(BuildContext context) async {
    final message = tr(context, 'whatsapp_message').replaceAll('{product}', productName);
    // WhatsApp URL format: https://wa.me/phone?text=urlencodedtext
    // Replace with actual business number
    final phone = "971500000000"; 
    final url = "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F9F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0F2F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'bulk_order').toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF1B222E),
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tr(context, 'bulk_order_sub'),
            style: TextStyle(
              color: const Color(0xFF1B222E).withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            tr(context, 'bulk_order_desc'),
            style: TextStyle(
              color: const Color(0xFF1B222E).withOpacity(0.4),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          
          // Minimum Order Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF00ACC1).withOpacity(0.2)),
            ),
            child: Text(
              tr(context, 'min_order_badge'),
              style: const TextStyle(
                color: Color(0xFF1B222E),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // WhatsApp Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _launchWhatsApp(context),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF25D366).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      tr(context, 'whatsapp_button'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
