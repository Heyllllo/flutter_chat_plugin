// example/lib/main.dart
import 'package:flutter/material.dart';
// Assuming your package name is 'heyllo_ai_chatbot' based on the import
// Adjust if your package name is different
import 'package:heyllo_ai_chatbot/chat_plugin.dart';

// Assuming a ColorPicker widget exists (like the one provided in the original example)
// If not, you'll need to add a color picker package like flutter_colorpicker
// For simplicity, I'll keep the ColorPicker class from your example below.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Plugin Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AdvancedChatDemo(),
    );
  }
}

class AdvancedChatDemo extends StatefulWidget {
  const AdvancedChatDemo({super.key});

  @override
  State<AdvancedChatDemo> createState() => _AdvancedChatDemoState();
}

class _AdvancedChatDemoState extends State<AdvancedChatDemo> {
  // --- Configuration ---
  static const domain = 'https://heyllo.co'; // Replace if needed
  static const chatbotId =
      'u12n4siq9ragdsftbpzgtktj'; // Replace with your actual chatbot ID

  // --- State Variables for Theming and Functionality ---
  Color _userBubbleColor = Colors.blue;
  Color _botBubbleColor = const Color(0xFFE1E1E1);
  Color _userTextColor = Colors.white;
  Color _botTextColor = Colors.black;
  double _bubbleRadius = 16.0;
  bool _showTimestamps = true; // Still controlled via ChatWidget param
  bool _showCitations = false; // New: Control citation visibility
  bool _isEnabled = true; // New: Control widget enable/disable state
  bool _usePresets = false;
  String _inputPlaceholder = 'Type a message...';

  // --- Theme Presets ---
  final Map<String, ChatTheme> _presets = {
    'Default': const ChatTheme(), // Uses defaults derived from app theme
    'Dark Mode': const ChatTheme(
      userBubbleColor: Colors.indigo,
      botBubbleColor: Color(0xFF303030), // Slightly lighter dark bubble
      userTextStyle: TextStyle(color: Colors.white),
      botTextStyle: TextStyle(color: Colors.white),
      backgroundColor: Color(0xFF121212),
      loadingIndicatorColor: Colors.white70,
      sendButtonColor: Colors.indigoAccent,
      sendButtonDisabledColor: Colors.grey,
    ),
    'Bubbly': ChatTheme(
      userBubbleColor: Colors.pinkAccent,
      botBubbleColor: Colors.purple.shade50,
      userTextStyle: const TextStyle(color: Colors.white),
      botTextStyle: const TextStyle(color: Colors.deepPurple),
      userBubbleBorderRadius: BorderRadius.circular(24),
      botBubbleBorderRadius: BorderRadius.circular(24),
      sendButtonColor: Colors.pinkAccent,
    ),
    'Professional': ChatTheme(
      userBubbleColor: Colors.blueGrey.shade700,
      botBubbleColor: Colors.blueGrey.shade50,
      userTextStyle: const TextStyle(color: Colors.white),
      botTextStyle: TextStyle(color: Colors.blueGrey.shade900),
      userBubbleBorderRadius: BorderRadius.circular(8),
      botBubbleBorderRadius: BorderRadius.circular(8),
      sendButtonColor: Colors.blueGrey.shade700,
      inputDecoration: InputDecoration(
          hintText: 'Enter your message...',
          filled: true,
          fillColor: Colors.white, // Ensure input contrasts with background
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blueGrey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blueGrey.shade700, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blueGrey.shade200),
          )),
      backgroundColor:
          const Color(0xFFF5F5F5), // Light background for pro theme
    ),
    'Minimalist': const ChatTheme(
      userBubbleColor: Colors.black,
      botBubbleColor: Color(0xFFF0F0F0),
      userTextStyle: TextStyle(color: Colors.white),
      botTextStyle: TextStyle(color: Colors.black),
      sendButtonColor: Colors.black,
      inputDecoration: InputDecoration(
        hintText: 'Message',
        border: UnderlineInputBorder(),
        focusedBorder:
            UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
        enabledBorder:
            UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
      userBubbleBorderRadius: BorderRadius.zero, // Square corners
      botBubbleBorderRadius: BorderRadius.zero,
    ),
  };

  String _selectedPreset = 'Default';

  @override
  Widget build(BuildContext context) {
    // Build current theme based on customization options
    // Note: If _usePresets is true, it completely overrides custom settings.
    final ChatTheme currentTheme = _usePresets
        ? _presets[_selectedPreset]!
        : ChatTheme(
            // Custom theme settings
            userBubbleColor: _userBubbleColor,
            botBubbleColor: _botBubbleColor,
            userTextStyle: TextStyle(
                color: _userTextColor, fontSize: 14), // Example font size
            botTextStyle: TextStyle(color: _botTextColor, fontSize: 14),
            userBubbleBorderRadius: BorderRadius.circular(_bubbleRadius),
            botBubbleBorderRadius: BorderRadius.circular(_bubbleRadius),
            inputDecoration: InputDecoration(
              // Example basic input decoration
              hintText: _inputPlaceholder,
              border: const OutlineInputBorder(), // Basic border
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            // Ensure other theme properties like button colors fallback nicely if not set
            // sendButtonColor: ...,
            // backgroundColor: ...,
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Plugin Demo'),
        actions: [
          // Toggle Enable/Disable Button
          IconButton(
            icon: Icon(_isEnabled ? Icons.toggle_on : Icons.toggle_off,
                color: _isEnabled ? Colors.green : Colors.grey),
            tooltip: _isEnabled ? 'Disable Chat' : 'Enable Chat',
            onPressed: () {
              setState(() {
                _isEnabled = !_isEnabled;
                print("Chat Enabled: $_isEnabled");
              });
            },
          ),
          // Settings Button
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Edit Theme',
            onPressed: () {
              _showThemeEditor();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Theme selector chips (only shown when presets are active)
          if (_usePresets)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: _presets.keys.map((String presetName) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(presetName),
                      selected: _selectedPreset == presetName,
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() {
                            _selectedPreset = presetName;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

          // Chat widget Area
          Expanded(
            // Use a key that changes when config changes force re-initialization
            child: ChatWidget(
              key: ValueKey(
                  '$domain/$chatbotId/$_isEnabled'), // Change key to force rebuild on critical changes
              domain: domain,
              chatbotId: chatbotId,
              theme: currentTheme, // Pass the calculated theme
              isEnabled: _isEnabled, // Pass the enable/disable state
              showTimestamps: _showTimestamps, // Pass timestamp visibility
              showCitations: _showCitations, // Pass citation visibility
              inputPlaceholder: _inputPlaceholder, // Pass placeholder override

              // Initial messages need the 'type' specified
              initialMessages: [
                ChatMessage(
                  message: 'Hello! How can I help you today?',
                  isUser: false,
                  type: 'content', // Explicitly set type
                  timestamp:
                      DateTime.now().subtract(const Duration(minutes: 5)),
                ),
                // Example error message (if needed)
                // ChatMessage(
                //   message: 'Example initial error message.',
                //   isUser: false,
                //   type: 'error',
                //   timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
                // ),
              ],

              // --- Callbacks ---
              onMessageSent: (message) {
                print("Message Sent: $message");
              },
              // Optional: Use specific callbacks if needed, otherwise UI updates automatically
              onResponseReceived: (response) {
                print("Final Response Content Received: $response");
              },
              onCitationsReceived: (citations) {
                print("Citations Received: ${citations.length}");
                // You could potentially display these outside the chat bubble if desired
              },
              onThreadIdReceived: (threadId) {
                print("Thread ID Received: $threadId");
                // Store this ID elsewhere if needed for other API calls
              },
              onError: (error) {
                print("Chat Error: $error");
                // Show error to user if appropriate
                if (mounted) {
                  // Check if widget is still in tree
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Chat Error: $error'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Theme Editor Modal ---
  void _showThemeEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows taller bottom sheet
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Use StatefulBuilder to manage state within the bottom sheet independently
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                  // Set max height
                  maxHeight: MediaQuery.of(context).size.height * 0.85),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize:
                    MainAxisSize.min, // Take only needed vertical space
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Theme Editor',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close))
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Toggle between presets and custom
                  Row(
                    children: [
                      const Text('Use preset themes:'),
                      const Spacer(),
                      Switch(
                        value: _usePresets,
                        onChanged: (value) {
                          // Update modal state AND main page state
                          setModalState(() => _usePresets = value);
                          setState(() => _usePresets = value);
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Content area (either presets or custom editor)
                  Expanded(
                    child: _usePresets
                        ? _buildPresetSelector(setModalState)
                        : _buildCustomThemeEditor(setModalState),
                  ),

                  // Apply button (optional, as changes apply live)
                  // SizedBox(
                  //   width: double.infinity,
                  //   child: ElevatedButton(
                  //     onPressed: () => Navigator.pop(context),
                  //     child: const Text('Close Editor'),
                  //   ),
                  // ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Preset Selector (Inside Modal) ---
  Widget _buildPresetSelector(StateSetter setModalState) {
    return ListView(
      shrinkWrap: true,
      children: _presets.entries.map((entry) {
        final String name = entry.key;
        final ChatTheme theme = entry.value;

        // Use default colors if preset doesn't specify them
        Color userColor = theme.userBubbleColor ?? Colors.grey;
        Color botColor = theme.botBubbleColor ?? Colors.grey[300]!;

        return Card(
          elevation: _selectedPreset == name ? 4 : 1, // Highlight selected
          margin: const EdgeInsets.only(bottom: 10),
          child: RadioListTile<String>(
            title: Text(name),
            value: name,
            groupValue: _selectedPreset,
            secondary: Row(
              // Show color swatches
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 10, backgroundColor: userColor),
                const SizedBox(width: 4),
                CircleAvatar(radius: 10, backgroundColor: botColor),
              ],
            ),
            onChanged: (String? value) {
              if (value != null) {
                // Update modal state AND main page state
                setModalState(() => _selectedPreset = value);
                setState(() => _selectedPreset = value);
              }
            },
          ),
        );
      }).toList(),
    );
  }

  // --- Custom Theme Editor (Inside Modal) ---
  Widget _buildCustomThemeEditor(StateSetter setModalState) {
    // Helper function for color picker rows
    Widget buildColorRow(
        String label, Color currentColor, Function(Color) onColorChanged) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label Color:'),
          GestureDetector(
            onTap: () async {
              final Color? pickedColor =
                  await showColorPicker(context, currentColor);
              if (pickedColor != null) {
                onColorChanged(pickedColor); // Updates state via callback
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: currentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      // Make editor scrollable
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context)
                .viewInsets
                .bottom), // Adjust for keyboard
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bubbles', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            buildColorRow("User Bubble", _userBubbleColor, (color) {
              setModalState(() => _userBubbleColor = color);
              setState(() => _userBubbleColor = color);
            }),
            const SizedBox(height: 8),
            buildColorRow("User Text", _userTextColor, (color) {
              setModalState(() => _userTextColor = color);
              setState(() => _userTextColor = color);
            }),
            const SizedBox(height: 16),
            buildColorRow("Bot Bubble", _botBubbleColor, (color) {
              setModalState(() => _botBubbleColor = color);
              setState(() => _botBubbleColor = color);
            }),
            const SizedBox(height: 8),
            buildColorRow("Bot Text", _botTextColor, (color) {
              setModalState(() => _botTextColor = color);
              setState(() => _botTextColor = color);
            }),

            const SizedBox(height: 20),
            Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
            // Bubble corner radius
            Row(
              children: [
                const Text('Bubble Radius:'),
                Expanded(
                  child: Slider(
                    value: _bubbleRadius,
                    min: 0,
                    max: 30,
                    divisions: 30,
                    label: _bubbleRadius.round().toString(),
                    onChanged: (value) {
                      setModalState(() => _bubbleRadius = value);
                      setState(() => _bubbleRadius = value);
                    },
                  ),
                ),
                Text('${_bubbleRadius.toInt()}px'),
              ],
            ),

            const SizedBox(height: 20),
            Text('Input Field', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _inputPlaceholder,
              decoration: const InputDecoration(
                labelText: 'Input Placeholder Text',
                border: OutlineInputBorder(),
                hintText: 'e.g., Type your question',
              ),
              onChanged: (value) {
                // No need for setModalState if changes apply live to main page state
                setState(() => _inputPlaceholder = value);
              },
            ),

            const SizedBox(height: 20),
            Text('Options', style: Theme.of(context).textTheme.titleMedium),
            SwitchListTile(
              title: const Text('Show Timestamps'),
              value: _showTimestamps,
              onChanged: (value) {
                setModalState(() => _showTimestamps = value);
                setState(() => _showTimestamps = value);
              },
              dense: true,
            ),
            SwitchListTile(
              title: const Text('Show Citations'),
              value: _showCitations,
              onChanged: (value) {
                setModalState(() => _showCitations = value);
                setState(() => _showCitations = value);
              },
              dense: true,
            ),
            // Add other options like background color picker if needed
          ],
        ),
      ),
    );
  }

  // --- Simple Color Picker Dialog (Keep from original) ---
  Future<Color?> showColorPicker(
      BuildContext context, Color initialColor) async {
    Color pickedColor = initialColor;
    // Using showDialog for the color picker
    return await showDialog<Color>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            // Assuming ColorPicker widget exists and works like flutter_colorpicker's basic version
            child: ColorPicker(
              // Replace with actual ColorPicker widget if different
              pickerColor: initialColor,
              onColorChanged: (color) {
                pickedColor = color; // Update local variable inside dialog
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () =>
                  Navigator.of(context).pop(null), // Return null on cancel
            ),
            TextButton(
              child: const Text('Select'),
              onPressed: () => Navigator.of(context)
                  .pop(pickedColor), // Return the picked color
            ),
          ],
        );
      },
    );
  }
}

// --- Simple Color Picker Widget (Keep from original example) ---
/// Simple color picker for demonstration purposes.
/// In a real app, consider using a package like flutter_colorpicker.
class ColorPicker extends StatefulWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;

  const ColorPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
  });

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late HSVColor _currentHsvColor;

  @override
  void initState() {
    super.initState();
    _currentHsvColor = HSVColor.fromColor(widget.pickerColor);
  }

  // Update when the initial color changes externally
  @override
  void didUpdateWidget(ColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pickerColor != oldWidget.pickerColor) {
      _currentHsvColor = HSVColor.fromColor(widget.pickerColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget slider(
        String label, double value, double max, Function(double) onChanged) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          Slider(
            value: value,
            min: 0,
            max: max,
            onChanged: onChanged,
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hue slider
        slider('Hue', _currentHsvColor.hue, 360, (value) {
          setState(() {
            _currentHsvColor = _currentHsvColor.withHue(value);
            widget.onColorChanged(_currentHsvColor.toColor());
          });
        }),

        // Saturation slider
        slider('Saturation', _currentHsvColor.saturation, 1, (value) {
          setState(() {
            _currentHsvColor = _currentHsvColor.withSaturation(value);
            widget.onColorChanged(_currentHsvColor.toColor());
          });
        }),

        // Value slider
        slider('Value (Brightness)', _currentHsvColor.value, 1, (value) {
          setState(() {
            _currentHsvColor = _currentHsvColor.withValue(value);
            widget.onColorChanged(_currentHsvColor.toColor());
          });
        }),

        // Alpha slider (optional)
        // slider('Alpha', _currentHsvColor.alpha, 1, (value) { ... }),

        // Preview
        const SizedBox(height: 10),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _currentHsvColor.toColor(),
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
        ),
      ],
    );
  }
}
