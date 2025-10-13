import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'choose_destination.dart';

class ChooseColorName extends StatefulWidget {
  const ChooseColorName({super.key});

  @override
  State<ChooseColorName> createState() => _ChooseColorNameState();
}

class _ChooseColorNameState extends State<ChooseColorName> {
  final TextEditingController _nameController = TextEditingController();
  Color? _selectedColor;
  
  final List<Color> _availableColors = [
    Colors.red,
    Colors.blue,
    const Color.fromARGB(255, 68, 156, 71),
    const Color.fromARGB(255, 154, 143, 44),
    Colors.black,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Color & Name'),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenSize.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: screenSize.height * 0.02),
            
            // Choose Name Section
            Text(
              'Choose Name',
              style: TextStyle(
                fontSize: screenSize.width * 0.06,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenSize.height * 0.02),
            
            // Name Input Field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter your name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.03,
                  vertical: screenSize.height * 0.02,
                ),
              ),
              style: TextStyle(fontSize: screenSize.width * 0.04),
            ),
            
            SizedBox(height: screenSize.height * 0.04),
            
            // Choose Color Section
            Text(
              'Choose Color',
              style: TextStyle(
                fontSize: screenSize.width * 0.06,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenSize.height * 0.02),
            
            // Color Selection Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: screenSize.width * 0.02,
                mainAxisSpacing: screenSize.height * 0.01,
                childAspectRatio: 1.2,
              ),
              itemCount: _availableColors.length,
              itemBuilder: (context, index) {
                final color = _availableColors[index];
                final isSelected = _selectedColor == color;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey,
                        width: isSelected ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 30,
                          )
                        : null,
                  ),
                );
              },
            ),
            
            SizedBox(height: screenSize.height * 0.05),
            
            // Submit Button
            ElevatedButton(
              onPressed: _canSubmit() ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: screenSize.height * 0.02,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Submit',
                style: TextStyle(
                  fontSize: screenSize.width * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            SizedBox(height: screenSize.height * 0.02),
          ],
        ),
      ),
    );
  }

  bool _canSubmit() {
    return _nameController.text.trim().isNotEmpty && _selectedColor != null;
  }

  void _submit() {
  if (_canSubmit()) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final playerName = _nameController.text.trim();
    final playerColor = _selectedColor!;
    
    // 1. Add the player (which calls saveGame() and updates state for everyone)
    gameProvider.addPlayer(playerName, playerColor);
    
    // 2. Find the index of the player that was just added.
    // This relies on the new player being the last in the *new* list.
    // This is still slightly race-condition prone, but is the best simple approach 
    // without using Firebase Authentication/UIDs for identification.
    final playerIndex = gameProvider.players.length - 1; 

    // Navigate to destination selection, passing the player's index
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChooseDestination(
          isInitialSelection: true,
          playerIndex: playerIndex, // <<< PASS THE INDEX
        ),
      ),
    );
  }
}
}
