import 'package:flutter/material.dart';

class GenreChipList extends StatelessWidget {
  final List<String> genres;
  final String selectedGenre;
  final Function(String) onSelected;

  const GenreChipList({
    super.key,
    required this.genres,
    required this.selectedGenre,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        children: genres.map((genre) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(genre),
              selected: selectedGenre == genre,
              onSelected: (_) => onSelected(genre),
            ),
          );
        }).toList(),
      ),
    );
  }
}