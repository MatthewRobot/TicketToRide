import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/destination.dart';
import 'player_screen.dart';

class ChooseDestination extends StatefulWidget {
  final bool isInitialSelection;
  final int? playerIndex;

  const ChooseDestination({
    super.key,
    this.isInitialSelection = true,
    this.playerIndex,
  });

  @override
  State<ChooseDestination> createState() => _ChooseDestinationState();
}

class _ChooseDestinationState extends State<ChooseDestination> {
  List<Destination> _availableDestinations = [];
  List<Destination> _selectedDestinations = [];
  bool _isLoading = true;
  bool _hasSubmitted = false;
  bool _destinationsLoaded = false; // NEW: Track if we've loaded destinations

  @override
  void initState() {
    super.initState();
    print('=== ChooseDestination initState called ===');
    print('Widget hash: ${widget.hashCode}');
    print('State hash: ${hashCode}');
    _loadDestinations();
  }

  @override
  void didUpdateWidget(ChooseDestination oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('=== ChooseDestination didUpdateWidget called ===');
    print('Old widget hash: ${oldWidget.hashCode}');
    print('New widget hash: ${widget.hashCode}');
    print('State hash: ${hashCode}');
    print('_destinationsLoaded: $_destinationsLoaded');
  }

  @override
  void dispose() {
    print('=== ChooseDestination dispose called ===');
    print('State hash: ${hashCode}');
    super.dispose();
  }

  void _loadDestinations() {
    print('=== _loadDestinations called ===');
    print('_destinationsLoaded: $_destinationsLoaded');
    print('_availableDestinations.length: ${_availableDestinations.length}');
    
    // Only load once
    if (_destinationsLoaded) {
      print('Skipping load - already loaded');
      return;
    }
    
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    print('Actually loading destinations...');
    // Get 3 new destinations for selection
    _availableDestinations = gameProvider.getNewDestinations();
    _destinationsLoaded = true;

    print('Loaded ${_availableDestinations.length} destinations for selection');
    print('Player index: ${widget.playerIndex}');
    print('Is initial selection: ${widget.isInitialSelection}');
    print('Destinations: ${_availableDestinations.map((d) => d.shortName).join(", ")}');

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('=== ChooseDestination build called ===');
    print('State hash: ${hashCode}');
    print('_destinationsLoaded: $_destinationsLoaded');
    print('_availableDestinations.length: ${_availableDestinations.length}');
    
    final screenSize = MediaQuery.of(context).size;
    // Use listen: false to prevent rebuilds from Firebase
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    
    // Determine which player is selecting
    final effectivePlayerIndex = widget.playerIndex ?? gameProvider.myPlayerIndex;
    
    if (effectivePlayerIndex == null || effectivePlayerIndex >= gameProvider.players.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Player not found')),
      );
    }

    final player = gameProvider.players[effectivePlayerIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('${player.name} - Choose Destinations'),
        centerTitle: true,
        backgroundColor: player.color,
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

                  Expanded(
                    child: ListView.builder(
                      itemCount: _availableDestinations.length,
                      itemBuilder: (context, index) {
                        final destination = _availableDestinations[index];
                        final isSelected =
                            _selectedDestinations.contains(destination);
                        final canSelect =
                            _selectedDestinations.length < 3 || isSelected;

                        return Container(
                          margin:
                              EdgeInsets.only(bottom: screenSize.height * 0.01),
                          child: Card(
                            elevation: isSelected ? 8 : 2,
                            color: isSelected ? Colors.blue[100] : Colors.white,
                            child: ListTile(
                              onTap: canSelect
                                  ? () => _toggleSelection(destination)
                                  : null,
                              title: Text(
                                destination.displayName,
                                style: TextStyle(
                                  fontSize: screenSize.width * 0.04,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.blue[800]
                                      : Colors.black,
                                ),
                              ),
                              subtitle: Text(
                                '${destination.points} points',
                                style: TextStyle(
                                  fontSize: screenSize.width * 0.035,
                                  color: isSelected
                                      ? Colors.blue[600]
                                      : Colors.grey[600],
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

                  Container(
                    padding: EdgeInsets.all(screenSize.width * 0.03),
                    decoration: BoxDecoration(
                      color:
                          _canSubmit() ? Colors.green[100] : Colors.grey[100],
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

                  ElevatedButton(
                    onPressed: _canSubmit() && !_hasSubmitted ? _submit : null,
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
                      _hasSubmitted ? 'Submitting...' : 'Submit Selection',
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
        if (_selectedDestinations.length < 3) {
          _selectedDestinations.add(destination);
        }
      }
    });
  }

  bool _canSubmit() {
    if (widget.isInitialSelection) {
      return _selectedDestinations.length >= 2 &&
          _selectedDestinations.length <= 3;
    } else {
      return _selectedDestinations.length >= 1 &&
          _selectedDestinations.length <= 3;
    }
  }

  void _submit() async {
    if (!_canSubmit() || _hasSubmitted) return;

    setState(() {
      _hasSubmitted = true;
    });

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final effectivePlayerIndex = widget.playerIndex ?? gameProvider.myPlayerIndex;

    if (effectivePlayerIndex == null || effectivePlayerIndex >= gameProvider.players.length) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Player identity lost. Please rejoin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final player = gameProvider.players[effectivePlayerIndex];
    
    // Cards that were not selected go back to used pile
    final unselectedDestinations = _availableDestinations.where(
      (d) => !_selectedDestinations.contains(d)
    ).toList();

    try {
      if (widget.isInitialSelection) {
        // Initial setup: no turn ends
        await gameProvider.addSelectedDestinationsSetup(
            player, _selectedDestinations, unselectedDestinations);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Selected ${_selectedDestinations.length} destination(s)',
              ),
            ),
          );

          // Navigate to player screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerScreen(
                playerIndex: effectivePlayerIndex,
              ),
            ),
            (route) => false,
          );
        }
      } else {
        // Mid-game: turn ends after selection
        await gameProvider.completeDestinationSelection(
            player, _selectedDestinations, unselectedDestinations);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Selected ${_selectedDestinations.length} destination(s)',
              ),
            ),
          );

          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      print('Error submitting destinations: $e');
      if (mounted) {
        setState(() {
          _hasSubmitted = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}