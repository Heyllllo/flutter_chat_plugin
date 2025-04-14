// lib/src/widgets/chat_bubble.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:url_launcher/url_launcher.dart'; // For launching links
import 'package:flutter_markdown/flutter_markdown.dart'; // Import the markdown package
import '../models/chat_message.dart';
import '../models/chat_theme.dart';
import 'typing_indicator.dart'; // Import the typing indicator

/// Displays a single chat message bubble with appropriate styling for user or bot.
/// Handles different message types (content, error) and optional display
/// of timestamps and citations. Renders bot messages as Markdown.
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final ChatTheme theme;
  final bool showAvatar;
  final bool showTimestamp;
  final bool showCitations; // Flag to control citation visibility
  final Widget? avatar; // Custom avatar widget
  final String? senderName; // Optional sender name display
  final EdgeInsetsGeometry? padding; // Custom padding inside the bubble
  final EdgeInsetsGeometry? margin; // Custom margin around the bubble
  final Function()? onTap; // Callback for tapping the bubble
  final Function()? onLongPress; // Callback for long-pressing the bubble
  final bool isError; // Flag indicating if this is an error message

  const ChatBubble({
    super.key,
    required this.message,
    required this.theme,
    this.showAvatar = false,
    this.showTimestamp = false,
    this.showCitations = false,
    this.avatar,
    this.senderName,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.isError = false,
  });

  /// Attempts to launch the given URL string in an external application.
  Future<void> _launchUrl(String urlString, BuildContext context) async {
    // Try adding scheme if missing
    Uri? url = Uri.tryParse(urlString);
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open invalid link: $urlString')),
      );
      return;
    }

    if (!url.hasScheme) {
      // Assume https if no scheme is present
      url = Uri.tryParse('https://$urlString');
      if (url == null || !url.hasScheme) {
        // Check again after adding scheme

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $urlString')),
        );
        return;
      }
    }

    try {
      bool canLaunch = await canLaunchUrl(url);
      if (canLaunch) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $url')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening link: $e')),
      );
    }
  }

  /// Copies the message text to the clipboard.
  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.message)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            duration: Duration(seconds: 1),
            content: Text('Message copied')), // Shorter duration
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final messageTimestamp =
        message.timestamp?.millisecondsSinceEpoch ?? 'null_ts';

    final appTheme = Theme.of(context);
    final isUser = message.isUser;

    // Determine styles based on user/bot and error state
    final decoration = isError
        ? _getErrorBubbleDecoration(context, appTheme)
        : (isUser
            ? theme.getUserBubbleDecoration(appTheme)
            : theme.getBotBubbleDecoration(appTheme));

    final textStyle = isError
        ? _getErrorTextStyle(context, appTheme)
        : (isUser
            ? theme.getUserTextStyle(appTheme)
            : theme.getBotTextStyle(appTheme));

    // Default margins for the ALIGNED bubble (when no avatar is shown)
    final EdgeInsetsGeometry effectiveMargin = margin ??
        EdgeInsets.only(
          left: isUser ? 40 : 8, // Standard margin when no avatar
          right: isUser ? 8 : 40, // Standard margin when no avatar
          top: 4,
          bottom: 4,
        );

    // Default padding inside the bubble
    final effectivePadding =
        padding ?? const EdgeInsets.symmetric(vertical: 10, horizontal: 14);

    // --- Build citations widget ---
    Widget citationsWidget = const SizedBox.shrink(); // Empty by default
    final citations = message.citations;
    if (showCitations && citations != null && citations.isNotEmpty) {
      citationsWidget = Padding(
        padding: const EdgeInsets.only(top: 8.0), // Space above citations
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Optional "Sources:" title
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                "Sources:",
                style: textStyle.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textStyle.color?.withAlpha(
                        (255 * 0.8).round()) // Slightly dimmer title
                    ),
              ),
            ),
            // List citations
            ...citations.map((citation) {
              final title = citation['title'] as String? ??
                  citation['url'] as String? ??
                  'Source'; // Use URL as title if title missing
              final url = citation['url'] as String?;
              bool isLink = url != null && url.isNotEmpty;

              return InkWell(
                onTap: isLink ? () => _launchUrl(url, context) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    // Use row for icon + text
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon indicating it's a link or just a source
                      Icon(
                        isLink ? Icons.link : Icons.info_outline,
                        size: 12,
                        color: textStyle.color?.withAlpha((255 * 0.8).round()),
                      ),
                      const SizedBox(width: 4),
                      // Citation text (title)
                      Expanded(
                        child: Text(
                          title,
                          style: textStyle.copyWith(
                            fontSize: 11,
                            // Style link differently
                            color: isLink
                                ? (theme.sendButtonColor ??
                                    appTheme.colorScheme
                                        .primary) // Use theme accent or primary
                                : textStyle.color?.withAlpha(
                                    (255 * 0.7).round()), // Dim non-links
                            decoration: isLink
                                ? TextDecoration.underline
                                : TextDecoration.none,
                            decorationColor: isLink
                                ? (theme.sendButtonColor ??
                                    appTheme.colorScheme.primary)
                                : null,
                          ),
                          maxLines:
                              1, // Prevent long titles from wrapping excessively
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      );
    }
    // --- End citations widget ---

    // --- Build main bubble content ---
    Widget bubbleContentContainer = Container(
      // Renamed for clarity before InkWell wrap
      padding: effectivePadding,
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align content left
        mainAxisSize: MainAxisSize.min, // Fit content height
        children: [
          // Sender name if provided and not user
          if (senderName != null && senderName!.isNotEmpty && !isUser)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                senderName!,
                style: textStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: textStyle.color
                      ?.withAlpha((255 * 0.9).round()), // Slightly dimmer name
                ),
              ),
            ),

          // *** RENDER MARKDOWN FOR BOT, PLAIN TEXT FOR USER/ERROR ***
          if (message.message.isNotEmpty ||
              isError) // Show even if empty if it's an error message
            if (!isUser &&
                !isError) // Render Markdown only for non-user, non-error messages
              MarkdownBody(
                data: message.message, // Pass the markdown string here
                selectable: true, // Allow text selection
                styleSheet: MarkdownStyleSheet.fromTheme(appTheme).copyWith(
                  // Base style on app theme
                  p: textStyle, // Apply the bubble's base text style to paragraphs
                  // You can customize other elements like headings, links, code blocks etc.
                  // h1: textStyle.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                  // a: TextStyle(color: theme.sendButtonColor ?? appTheme.colorScheme.primary, decoration: TextDecoration.underline),
                  // code: TextStyle(backgroundColor: appTheme.colorScheme.surfaceVariant, fontFamily: 'monospace'),
                ),
                onTapLink: (text, href, title) {
                  // Handle link taps
                  if (href != null) {
                    _launchUrl(href, context);
                  }
                },
                // Add other configurations like image builders if needed
                // imageBuilder: (uri, title, alt) => Image.network(uri.toString()),
              )
            else // For user messages or errors, use SelectableText
              SelectableText(message.message, style: textStyle),
          // *** END MARKDOWN RENDERING ***

          // Typing indicator OR Citations/Timestamp
          if (message.isWaiting)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              // Use the imported BubbleTypingIndicator
              child: BubbleTypingIndicator(
                color: theme.loadingIndicatorColor ??
                    (isUser
                            ? appTheme.colorScheme.onPrimary
                            : appTheme.colorScheme.primary)
                        .withAlpha((255 * 0.7).round()),
                bubbleSize: 8,
                spacing: 4,
              ),
            )
          else ...[
            // Show these only if not waiting
            // Citations widget (built above)
            citationsWidget,

            // Timestamp if enabled and available
            if (showTimestamp && message.timestamp != null)
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  // Adjust top padding based on whether citations are shown
                  padding: EdgeInsets.only(
                      top: (citationsWidget is SizedBox &&
                              citationsWidget.height == 0)
                          ? 4
                          : 8),
                  child: Text(
                    _formatTimestamp(message.timestamp!),
                    style: textStyle.copyWith(
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w300, // Lighter weight for timestamp
                      color: textStyle.color
                          ?.withAlpha((255 * 0.6).round()), // Dimmer timestamp
                    ),
                  ),
                ),
              ),
          ]
        ],
      ),
    );
    // --- End main bubble content container ---

    // --- Add InkWell for tap/long-press AFTER content is built ---
    // This makes the whole bubble area tappable, including padding
    Widget bubbleInteractive = Material(
      // Material needed for InkWell splash and borderRadius clipping
      color: Colors.transparent, // Make material transparent
      borderRadius: (decoration is BoxDecoration)
          ? (decoration.borderRadius
              as BorderRadius?) // Cast BorderRadiusGeometry? to BorderRadius?
          : BorderRadius.circular(16), // Fallback if needed
      clipBehavior: Clip.antiAlias, // Ensure InkWell splash stays within bounds
      child: InkWell(
        onTap: onTap,
        // Add default long press for copying if no custom one is provided
        onLongPress: onLongPress ??
            (isError || message.message.isEmpty
                ? null
                : () => _copyToClipboard(context)),
        // borderRadius applied to Material above
        child: bubbleContentContainer, // Wrap the content container
      ),
    );
    // --- End InkWell ---

    // --- Row for Avatar + Bubble ---
    if (showAvatar) {
      final effectiveAvatar = avatar ?? _defaultAvatar(isUser, appTheme);
      // Define specific padding for the Row when avatar is shown
      final double verticalPadding = (effectiveMargin is EdgeInsets)
          ? effectiveMargin.top // Use top/bottom from original margin
          : 4.0; // Default vertical padding
      final EdgeInsets avatarRowPadding = EdgeInsets.symmetric(
        horizontal: 8.0, // Standard horizontal padding when avatar is shown
        vertical: verticalPadding,
      );

      return Padding(
        padding: avatarRowPadding, // Use the calculated EdgeInsets
        child: Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment:
              CrossAxisAlignment.end, // Align avatar bottom with bubble bottom
          children: isUser
              ? [
                  Flexible(
                      child: bubbleInteractive), // Bubble takes available space
                  const SizedBox(width: 8),
                  effectiveAvatar, // Avatar on the right for user
                ]
              : [
                  effectiveAvatar, // Avatar on the left for bot
                  const SizedBox(width: 8),
                  Flexible(child: bubbleInteractive),
                ],
        ),
      );
    }
    // --- End Avatar Row ---

    // --- Bubble only (no avatar) ---
    // Align the bubble itself left or right
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        // Constrain max width to prevent bubble taking full screen width
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin:
            effectiveMargin, // Use the original margin (passed in or default)
        child: bubbleInteractive, // The InkWell-wrapped content
      ),
    );
    // --- End Bubble only ---
  }

  /// Formats the timestamp to HH:MM format.
  String _formatTimestamp(DateTime timestamp) {
    // Use local time
    final localTimestamp = timestamp.toLocal();
    return '${localTimestamp.hour.toString().padLeft(2, '0')}:${localTimestamp.minute.toString().padLeft(2, '0')}';
  }

  /// Creates a default circular avatar widget.
  Widget _defaultAvatar(bool isUser, ThemeData theme) {
    // Determine background color based on theme or defaults
    Color? avatarBackgroundColor =
        isUser ? this.theme.userBubbleColor : this.theme.botBubbleColor;
    // Fallback if theme colors are null
    avatarBackgroundColor ??=
        isUser ? theme.colorScheme.primary : theme.colorScheme.secondary;

    // Determine icon/text color based on theme or calculated contrast
    Color? avatarForegroundColor = isUser
        ? this.theme.userTextStyle?.color
        : this.theme.botTextStyle?.color;
    // Fallback: Calculate contrast if text style color is null
    avatarForegroundColor ??=
        ThemeData.estimateBrightnessForColor(avatarBackgroundColor) ==
                Brightness.dark
            ? Colors.white
            : Colors.black;

    return CircleAvatar(
      radius: 16, // Standard avatar size
      backgroundColor: avatarBackgroundColor,
      child: Icon(
        isUser
            ? Icons.person_outline
            : Icons.support_agent_outlined, // Use outlined icons
        size: 18, // Slightly larger icon
        color: avatarForegroundColor, // Use calculated/themed color
      ),
    );
  }

  /// Defines the decoration for error message bubbles.
  BoxDecoration _getErrorBubbleDecoration(
      BuildContext context, ThemeData appTheme) {
    // Use error colors from the theme
    return BoxDecoration(
      color: appTheme.colorScheme.errorContainer
          .withAlpha((255 * 0.9).round()), // Slightly transparent error bg
      borderRadius: theme.botBubbleBorderRadius ??
          BorderRadius.circular(16), // Use bot radius or default
      // Optional: Add a subtle border
      // border: Border.all(color: appTheme.colorScheme.error, width: 0.5),
    );
  }

  /// Defines the text style for error messages.
  TextStyle _getErrorTextStyle(BuildContext context, ThemeData appTheme) {
    // Use onError color from the theme for good contrast
    return TextStyle(
      color: appTheme.colorScheme.onErrorContainer,
      fontSize: 14, // Match default text size or customize
    );
  }
}
