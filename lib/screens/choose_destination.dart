import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/destination.dart';
import 'player_screen.dart';

class ChooseDestination extends StatefulWidget {
  final bool isInitialSelection;
  
  const ChooseDestination({
    super.key,
    this.isInitialSelection = true,
  });

  @override
  State<ChooseDestination> createState() => _ChooseDestinationState();
}

class _ChooseDestinationState extends State<ChooseDestination> {
  List<Destination> _availableDestinations = [];
  List<Destination> _selectedDestinations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDestinations();
  }

  void _loadDestinations() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    
    // Get 3 new destinations for selection
    _availableDestinations = gameProvider.getNewDestinations();
    
    // Debug info
    print('Loaded ${_availableDestinations.length} destinations for selection');
    print('Is initial selection: ${widget.isInitialSelection}');
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Destination'),
        centerTitle: true,
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(screenSize.width * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: screenSize.height * 0.02),
                  
                  // Instructions
                  Text(
                    widget.isInitialSelection
                        ? 'Choose destinations to keep (2-3 cards):'
                        : 'Choose destinations to keep (1-3 cards):',
                    style: TextStyle(
                      fontSize: screenSize.width * 0.05,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: screenSize.height * 0.03),
                  
                  // Destination cards
                  Expanded(
                    child: ListView.builder(
                      itemCount: _availableDestinations.length,
                      itemBuilder: (context, index) {
                        final destination = _availableDestinations[index];
                        final isSelected = _selectedDestinations.contains(destination);
                        final maxSelection = 3; // Both initial and mid-game allow up to 3 cards
                        final canSelect = _selectedDestinations.length < maxSelection || isSelected;
                        
                        return Container(
                          margin: EdgeInsets.only(bottom: screenSize.height * 0.01),
                          child: Card(
                            elevation: isSelected ? 8 : 2,
                            color: isSelected ? Colors.blue[100] : Colors.white,
                            child: ListTile(
                              onTap: canSelect ? () => _toggleSelection(destination) : null,
                              title: Text(
                                destination.displayName,
                                style: TextStyle(
                                  fontSize: screenSize.width * 0.04,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.blue[800] : Colors.black,
                                ),
                              ),
                              subtitle: Text(
                                '${destination.points} points',
                                style: TextStyle(
                                  fontSize: screenSize.width * 0.035,
                                  color: isSelected ? Colors.blue[600] : Colors.grey[600],
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      color: Colors.blue[800],
                                      size: screenSize.width * 0.06,
                                    )
                                  : Icon(
                                      Icons.radio_button_unchecked,
                                      color: Colors.grey[400],
                                      size: screenSize.width * 0.06,
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  SizedBox(height: screenSize.height * 0.02),
                  
                  // Selection info
                  Container(
                    padding: EdgeInsets.all(screenSize.width * 0.03),
                    decoration: BoxDecoration(
                      color: _canSubmit() ? Colors.green[100] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Selected: ${_selectedDestinations.length}/3',
                          style: TextStyle(
                            fontSize: screenSize.width * 0.04,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: screenSize.height * 0.005),
                        Text(
                          widget.isInitialSelection
                              ? 'Keep 2-3 cards'
                              : 'Keep 1-3 cards',
                          style: TextStyle(
                            fontSize: screenSize.width * 0.03,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: screenSize.height * 0.02),
                  
                  // Submit button
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
                      'Submit Selection',
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

  void _toggleSelection(Destination destination) {
    setState(() {
      if (_selectedDestinations.contains(destination)) {
        _selectedDestinations.remove(destination);
      } else {
        // Allow up to 3 cards for both initial and mid-game selection
        if (_selectedDestinations.length < 3) {
          _selectedDestinations.add(destination);
        }
      }
    });
  }

  bool _canSubmit() {
    if (widget.isInitialSelection) {
      // Initial selection: must keep 2-3 cards
      return _selectedDestinations.length >= 2 && _selectedDestinations.length <= 3;
    } else {
      // Mid-game selection: must keep 1-3 cards
      return _selectedDestinations.length >= 1 && _selectedDestinations.length <= 3;
    }
  }

  void _submit() {
    if (_canSubmit()) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      
      // Add selected destinations to the most recently added player
      if (gameProvider.players.isNotEmpty) {
        final player = gameProvider.players.last; // Get the most recently added player
        gameProvider.addSelectedDestinations(player, _selectedDestinations);
        
        // Navigate to player screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerScreen(
              playerIndex: gameProvider.players.length - 1,
            ),
          ),
          (route) => false, // Remove all previous routes
        );
      }
      
      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selected ${_selectedDestinations.length} destination(s)',
          ),
        ),
      );
    }
  }
}
