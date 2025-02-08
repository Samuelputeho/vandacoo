import 'package:flutter/material.dart';

class GlobalCommentsInput extends StatefulWidget {
  final String postId;
  final String userId;
  final String posterUserName;
  final Function(String) onSubmit;
  static const int maxCommentLength = 500;

  const GlobalCommentsInput({
    super.key,
    required this.postId,
    required this.userId,
    required this.posterUserName,
    required this.onSubmit,
  });

  @override
  State<GlobalCommentsInput> createState() => _GlobalCommentsInputState();
}

class _GlobalCommentsInputState extends State<GlobalCommentsInput> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _isComposing = _commentController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitComment() {
    if (_commentController.text.isNotEmpty) {
      if (_commentController.text.length >
          GlobalCommentsInput.maxCommentLength) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Comment cannot exceed ${GlobalCommentsInput.maxCommentLength} characters'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      widget.onSubmit(_commentController.text);
      _commentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 5,
        left: 16,
        right: 16,
        top: 8,
      ),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: isDarkMode
                ? Colors.white.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                focusNode: _focusNode,
                maxLength: GlobalCommentsInput.maxCommentLength,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Add a comment for ${widget.posterUserName}...',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.4)
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.send,
                color: _isComposing
                    ? (isDarkMode
                        ? Colors.white
                        : Theme.of(context).primaryColor)
                    : (isDarkMode ? Colors.grey[600] : Colors.grey[400]),
              ),
              onPressed: _isComposing ? _submitComment : null,
            ),
          ],
        ),
      ),
    );
  }
}
