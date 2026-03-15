import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myoffgridai_client/core/api/api_exception.dart';
import 'package:myoffgridai_client/core/services/knowledge_service.dart';
import 'package:myoffgridai_client/shared/widgets/loading_indicator.dart';

/// Rich text document editor for creating and editing knowledge documents.
///
/// When [documentId] is null, creates a new document. Otherwise loads
/// and edits the existing document's content (Quill Delta JSON).
class DocumentEditorScreen extends ConsumerStatefulWidget {
  /// The ID of the document to edit, or null to create a new document.
  final String? documentId;

  /// Creates a [DocumentEditorScreen].
  const DocumentEditorScreen({super.key, this.documentId});

  @override
  ConsumerState<DocumentEditorScreen> createState() =>
      _DocumentEditorScreenState();
}

class _DocumentEditorScreenState extends ConsumerState<DocumentEditorScreen> {
  QuillController? _quillController;
  final TextEditingController _titleController = TextEditingController();
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isNewDocument => widget.documentId == null;

  @override
  void initState() {
    super.initState();
    if (_isNewDocument) {
      _quillController = QuillController.basic();
    } else {
      _loadContent();
    }
  }

  @override
  void dispose() {
    _quillController?.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(knowledgeServiceProvider);
      final content = await service.getDocumentContent(widget.documentId!);
      _titleController.text = content.title;

      if (content.content != null && content.content!.isNotEmpty) {
        try {
          final deltaJson = jsonDecode(content.content!) as List<dynamic>;
          final doc = Document.fromJson(deltaJson);
          _quillController = QuillController(
            document: doc,
            selection: const TextSelection.collapsed(offset: 0),
          );
        } catch (_) {
          // If Delta JSON parsing fails, treat as plain text
          _quillController = QuillController.basic();
          _quillController!.document.insert(0, content.content!);
        }
      } else {
        _quillController = QuillController.basic();
      }

      if (mounted) setState(() => _isLoading = false);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load document content.';
        });
      }
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    if (_quillController == null) return;

    setState(() => _isSaving = true);

    try {
      final deltaJson = jsonEncode(
        _quillController!.document.toDelta().toJson(),
      );
      final service = ref.read(knowledgeServiceProvider);

      if (_isNewDocument) {
        await service.createDocument(title: title, content: deltaJson);
      } else {
        await service.updateDocumentContent(widget.documentId!, deltaJson);
      }

      ref.invalidate(knowledgeDocumentsProvider);
      if (widget.documentId != null) {
        ref.invalidate(documentContentProvider(widget.documentId!));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isNewDocument
                ? 'Document created'
                : 'Document updated'),
          ),
        );
        context.go('/knowledge');
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/knowledge'),
        ),
        title: Text(_isNewDocument ? 'New Document' : 'Edit Document'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _save,
            tooltip: 'Save',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator();
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadContent,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_quillController == null) {
      return const LoadingIndicator();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
          ),
        ),
        QuillSimpleToolbar(controller: _quillController!),
        const Divider(height: 1),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: QuillEditor.basic(controller: _quillController!),
          ),
        ),
      ],
    );
  }
}
