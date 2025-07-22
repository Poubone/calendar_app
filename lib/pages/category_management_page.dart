import 'package:flutter/material.dart';
import 'package:calendar_app/services/event_service.dart';
import 'package:calendar_app/models/category.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class CategoryManagementPage extends StatefulWidget {
  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  List<Category> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _loading = true);
    final cats = await EventService.fetchCategories();
    setState(() {
      _categories = cats;
      _loading = false;
    });
  }

  Future<void> _addCategory() async {
    String name = '';
    Color color = Colors.blue;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Nouvelle catégorie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Nom'),
                onChanged: (v) => name = v,
              ),
              const SizedBox(height: 16),
              BlockPicker(
                pickerColor: color,
                onColorChanged: (c) => color = c,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (name.trim().isEmpty) return;
                final colorHex = '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
                await EventService.createCategory(name.trim(), colorHex);
                Navigator.pop(context);
                _fetchCategories();
              },
              child: const Text('Créer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCategory(Category cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Supprimer la catégorie "${cat.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await EventService.deleteCategory(cat.id);
        _fetchCategories();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de supprimer cette catégorie : elle est utilisée par au moins un événement.', style: TextStyle(color: Colors.white))),
        );
      }
    }
  }

  Future<void> _changeColor(Category cat) async {
    Color color = cat.color != null ? Color(int.parse(cat.color!.replaceFirst('#', '0xFF'))) : Colors.blue;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Changer la couleur'),
          content: BlockPicker(
            pickerColor: color,
            onColorChanged: (c) => color = c,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final colorHex = '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
                try {
                  await EventService.deleteCategory(cat.id);
                  await EventService.createCategory(cat.name, colorHex);
                  Navigator.pop(context);
                  _fetchCategories();
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Impossible de modifier la couleur : la catégorie est utilisée par au moins un événement.', style: TextStyle(color: Colors.white))),
                  );
                }
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des catégories', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, i) {
                final cat = _categories[i];
                return ListTile(
                  leading: CircleAvatar(backgroundColor: cat.color != null ? Color(int.parse(cat.color!.replaceFirst('#', '0xFF'))) : Colors.grey),
                  title: Text(cat.name, style: GoogleFonts.poppins()),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.color_lens),
                        tooltip: 'Changer la couleur',
                        onPressed: () => _changeColor(cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: 'Supprimer',
                        onPressed: () => _deleteCategory(cat),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCategory,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
} 