package gameboard_revamped;

import haxe.ds.ReadOnlyArray;
import net.shared.board.Hex;
import net.shared.board.HexCoords;
import net.shared.PieceColor;

typedef MarkerLocationsGetter = (departureLocation:HexCoords, hexRetriever:HexCoords->Hex)->Array<HexCoords>;
typedef HexSelectabilityChecker = (candidateLocation:HexCoords, hexRetriever:HexCoords->Hex)->Bool;

enum InteractivityMode 
{
    MoveSelection(controllablePieces:ReadOnlyArray<PieceColor>, markerLocations:Null<MarkerLocationsGetter>);
    HexSelection(selectabilityChecker:HexSelectabilityChecker);
    NotInteractive;    
}