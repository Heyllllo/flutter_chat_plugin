// example/lib/main.dart
import 'package:flutter/material.dart';
import 'package:chat_plugin/chat_plugin.dart';
import 'package:chat_plugin/src/models/chat_theme.dart';

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
  static const domain = 'https://heyllo.co';
  static const chatbotId =
      'zqrfsxffb2fkjllyrlj73ddq'; // Replace with your actual chatbot ID

  // Theme customization options
  Color _userBubbleColor = Colors.blue;
  Color _botBubbleColor = const Color(0xFFE1E1E1);
  Color _userTextColor = Colors.white;
  Color _botTextColor = Colors.black;
  double _bubbleRadius = 16.0;
  bool _showAvatars = true;
  bool _showTimestamps = true;
  bool _usePresets = false;
  String _inputPlaceholder = 'Type a message...';

  // Theme presets
  final Map<String, ChatTheme> _presets = {
    'Default': const ChatTheme(),
    'Dark Mode': const ChatTheme(
      userBubbleColor: Colors.indigo,
      botBubbleColor: Color(0xFF2D2D2D),
      userTextStyle: TextStyle(color: Colors.white),
      botTextStyle: TextStyle(color: Colors.white),
      backgroundColor: Color(0xFF121212),
      loadingIndicatorColor: Colors.white,
      sendButtonColor: Colors.indigo,
    ),
    'Bubbly': ChatTheme(
      userBubbleColor: Colors.pink,
      botBubbleColor: Colors.purple.shade50,
      userTextStyle: const TextStyle(color: Colors.white),
      botTextStyle: const TextStyle(color: Colors.purple),
      userBubbleBorderRadius: BorderRadius.circular(24),
      botBubbleBorderRadius: BorderRadius.circular(24),
      sendButtonColor: Colors.pink,
    ),
    'Professional': ChatTheme(
      userBubbleColor: Colors.blueGrey.shade700,
      botBubbleColor: Colors.blueGrey.shade50,
      userTextStyle: const TextStyle(color: Colors.white),
      botTextStyle: TextStyle(color: Colors.blueGrey.shade700),
      userBubbleBorderRadius: BorderRadius.circular(8),
      botBubbleBorderRadius: BorderRadius.circular(8),
      sendButtonColor: Colors.blueGrey.shade700,
      inputDecoration: InputDecoration(
        hintText: 'Enter your message...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blueGrey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blueGrey.shade700, width: 2),
        ),
      ),
    ),
    'Minimalist': const ChatTheme(
      userBubbleColor: Colors.black,
      botBubbleColor: Color(0xFFF5F5F5),
      userTextStyle: TextStyle(color: Colors.white),
      botTextStyle: TextStyle(color: Colors.black),
      sendButtonColor: Colors.black,
      inputDecoration: InputDecoration(
        hintText: 'Message',
        border: UnderlineInputBorder(),
      ),
    ),
  };

  String _selectedPreset = 'Default';

  @override
  Widget build(BuildContext context) {
    // Build current theme based on customization options
    final ChatTheme currentTheme = _usePresets
        ? _presets[_selectedPreset]!
        : ChatTheme(
            userBubbleColor: _userBubbleColor,
            botBubbleColor: _botBubbleColor,
            userTextStyle: TextStyle(color: _userTextColor),
            botTextStyle: TextStyle(color: _botTextColor),
            userBubbleBorderRadius: BorderRadius.circular(_bubbleRadius),
            botBubbleBorderRadius: BorderRadius.circular(_bubbleRadius),
            inputDecoration: InputDecoration(
              hintText: _inputPlaceholder,
              border: const OutlineInputBorder(),
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Theming Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showThemeEditor();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Theme selector chips
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

          // Chat widget
          Expanded(
            child: ChatWidget(
              domain: domain,
              chatbotId: chatbotId,
              theme: currentTheme,
              showTimestamps: _showTimestamps,
              initialMessages: [
                ChatMessage(
                  message: 'Hello! How can I help you today?',
                  isUser: false,
                  timestamp:
                      DateTime.now().subtract(const Duration(minutes: 5)),
                ),
                ChatMessage(
                  message: 'Ask me anything',
                  isUser: false,
                  timestamp:
                      DateTime.now().subtract(const Duration(minutes: 5)),
                ),
              ],
              onError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $error')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Theme Editor',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
                          setModalState(() {
                            _usePresets = value;
                          });
                          setState(() {
                            _usePresets = value;
                          });
                        },
                      ),
                    ],
                  ),

                  const Divider(),

                  Expanded(
                    child: _usePresets
                        ? _buildPresetSelector(setModalState)
                        : _buildCustomThemeEditor(setModalState),
                  ),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Apply Theme'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPresetSelector(StateSetter setModalState) {
    return ListView(
      children: _presets.entries.map((entry) {
        final String name = entry.key;
        final ChatTheme theme = entry.value;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            title: Text(name),
            leading: CircleAvatar(
              backgroundColor: theme.userBubbleColor ?? Colors.blue,
            ),
            trailing: Radio<String>(
              value: name,
              groupValue: _selectedPreset,
              onChanged: (String? value) {
                setModalState(() {
                  _selectedPreset = value!;
                });
                setState(() {
                  _selectedPreset = value!;
                });
              },
            ),
            onTap: () {
              setModalState(() {
                _selectedPreset = name;
              });
              setState(() {
                _selectedPreset = name;
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomThemeEditor(StateSetter setModalState) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('User Bubble',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // User bubble color
          Row(
            children: [
              const Text('Color:'),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () async {
                  final Color? pickedColor = await showColorPicker(
                    context,
                    _userBubbleColor,
                  );
                  if (pickedColor != null) {
                    setModalState(() {
                      _userBubbleColor = pickedColor;
                    });
                    setState(() {
                      _userBubbleColor = pickedColor;
                    });
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _userBubbleColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey,
                      width: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // User text color
              const Text('Text:'),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () async {
                  final Color? pickedColor = await showColorPicker(
                    context,
                    _userTextColor,
                  );
                  if (pickedColor != null) {
                    setModalState(() {
                      _userTextColor = pickedColor;
                    });
                    setState(() {
                      _userTextColor = pickedColor;
                    });
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _userTextColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Text('Bot Bubble',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Bot bubble color
          Row(
            children: [
              const Text('Color:'),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () async {
                  final Color? pickedColor = await showColorPicker(
                    context,
                    _botBubbleColor,
                  );
                  if (pickedColor != null) {
                    setModalState(() {
                      _botBubbleColor = pickedColor;
                    });
                    setState(() {
                      _botBubbleColor = pickedColor;
                    });
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _botBubbleColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey,
                      width: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Bot text color
              const Text('Text:'),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () async {
                  final Color? pickedColor = await showColorPicker(
                    context,
                    _botTextColor,
                  );
                  if (pickedColor != null) {
                    setModalState(() {
                      _botTextColor = pickedColor;
                    });
                    setState(() {
                      _botTextColor = pickedColor;
                    });
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _botTextColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Bubble corner radius
          Row(
            children: [
              const Text('Bubble radius:'),
              const SizedBox(width: 16),
              Expanded(
                child: Slider(
                  value: _bubbleRadius,
                  min: 0,
                  max: 24,
                  divisions: 24,
                  label: _bubbleRadius.round().toString(),
                  onChanged: (value) {
                    setModalState(() {
                      _bubbleRadius = value;
                    });
                    setState(() {
                      _bubbleRadius = value;
                    });
                  },
                ),
              ),
              Text('${_bubbleRadius.toInt()}'),
            ],
          ),

          // Input placeholder
          const SizedBox(height: 16),
          const Text('Input placeholder:'),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _inputPlaceholder,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter placeholder text',
            ),
            onChanged: (value) {
              setModalState(() {
                _inputPlaceholder = value;
              });
              setState(() {
                _inputPlaceholder = value;
              });
            },
          ),

          const SizedBox(height: 16),

          // Toggle options
          CheckboxListTile(
            title: const Text('Show avatars'),
            value: _showAvatars,
            onChanged: (value) {
              setModalState(() {
                _showAvatars = value!;
              });
              setState(() {
                _showAvatars = value!;
              });
            },
          ),

          CheckboxListTile(
            title: const Text('Show timestamps'),
            value: _showTimestamps,
            onChanged: (value) {
              setModalState(() {
                _showTimestamps = value!;
              });
              setState(() {
                _showTimestamps = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Future<Color?> showColorPicker(
      BuildContext context, Color initialColor) async {
    Color pickedColor = initialColor;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: initialColor,
              onColorChanged: (color) {
                pickedColor = color;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                pickedColor = initialColor;
              },
            ),
            TextButton(
              child: const Text('Select'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    return pickedColor;
  }
}

/// Simple color picker for demonstration purposes
/// In a real app, you might want to use a package like flutter_colorpicker
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hue slider
        const Text('Hue'),
        Slider(
          value: _currentHsvColor.hue,
          min: 0,
          max: 360,
          onChanged: (value) {
            setState(() {
              _currentHsvColor = _currentHsvColor.withHue(value);
              widget.onColorChanged(_currentHsvColor.toColor());
            });
          },
        ),

        // Saturation slider
        const Text('Saturation'),
        Slider(
          value: _currentHsvColor.saturation,
          min: 0,
          max: 1,
          onChanged: (value) {
            setState(() {
              _currentHsvColor = _currentHsvColor.withSaturation(value);
              widget.onColorChanged(_currentHsvColor.toColor());
            });
          },
        ),

        // Value slider
        const Text('Value (Brightness)'),
        Slider(
          value: _currentHsvColor.value,
          min: 0,
          max: 1,
          onChanged: (value) {
            setState(() {
              _currentHsvColor = _currentHsvColor.withValue(value);
              widget.onColorChanged(_currentHsvColor.toColor());
            });
          },
        ),

        // Preview
        const SizedBox(height: 10),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _currentHsvColor.toColor(),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
