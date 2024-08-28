{
  ESS-Model
  Copyright (C) 2002  Eldean AB, Peter Söderman, Ville Krumlinde

  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
}

unit SugiyamaLayout;

{
  Layout according to the 'Sugiyama'-algoritm.
}

interface

{$ifdef WIN32}
uses essLayout, contnrs, Controls;
{$endif}
{$ifdef LINUX}
uses essLayout, contnrs, QControls;
{$endif}


type
  TEdgeList = class;

  TNode = class
  private
    Id : integer;     //Index i nodes-listan, måste uppdateras när nod byter plats (efter sortering)
    InEdges,OutEdges : TEdgeList;
    Rank : integer;
    Order : integer;
    COrder : integer;
    Weight : single;
    IsDummy : boolean;
    X,Y,H,W : integer;
    Control : TControl;
    constructor Create;
  public
    destructor Destroy; override;
  end;

  TEdge = class
  private
    FromNode,ToNode : TNode;
    constructor Create(const FromNode,ToNode : TNode);
  end;

  {$HINTS OFF}
  TEdgeList = class(TObjectList)
  private
    function GetEdge(Index: Integer): TEdge;
    property Edges[Index: Integer]: TEdge read GetEdge; default;
  end;
  TNodeList = class(TObjectList)
  private
    function GetNode(Index: Integer): TNode;
    function LastIndexOf(const P : pointer) : integer;
    property Nodes[Index: Integer]: TNode read GetNode; default;
  end;
  TLayerList = class(TObjectList)
  private
    function GetLayer(Index: Integer): TNodeList;
    property Layers[Index: Integer]: TNodeList read GetLayer; default;
  end;
  {$HINTS ON}

  TSugiyamaLayout = class(TEssLayout)
  private
    Nodes : TNodeList;
    Layers : TLayerList;
    procedure ExtractNodes;
    procedure ApplyNodes;
    procedure DoPhases;
    procedure AddEdge(const FromNode,ToNode : TNode);

    //Första steget
    procedure LayeringPhase;
    procedure MakeAcyclic;
    procedure InitialRanking;
    procedure MakeProper;
    procedure TopoSort;

    //Andra steget
    procedure OrderingPhase;
    function CalcCrossings : integer;
    function CalcCrossingsTwoLayers(const Layer1,Layer2 : TNodeList) : integer;

    //Tredje steget
    procedure PositioningPhase;
    procedure SetXPositions;
    procedure SetYPositions;
  public
    procedure Execute; override;
    destructor Destroy; override;
  end;


implementation

uses Classes,
     essConnectPanel,
     Math,
     SysUtils;



{ TSugiyamaLayout }

procedure TSugiyamaLayout.Execute;
begin
  ExtractNodes;
  DoPhases;
  ApplyNodes;
end;


//Drar ur noder ifrån essconnectpanel
procedure TSugiyamaLayout.ExtractNodes;
var
  L : TList;
  I : integer;
  C : TControl;
  Con : essConnectPanel.TConnection;
  Node,FromNode,ToNode : TNode;
begin
  Nodes := TNodeList.Create(True);

  L := Panel.GetManagedObjects;
  try
    for I := 0 to L.Count-1 do
    begin
      C := TControl(L[I]);
      if not C.Visible then
        Continue;
      Node := TNode.Create;
      Node.H := C.Height;
      Node.W := C.Width;
      Node.Control := C;
      Node.Id := Nodes.Count;
      C.Tag := Node.Id;
      Nodes.Add(Node);
    end;
  finally
    L.Free;
  end;

  L := Panel.GetConnections;
  try
    for I := 0 to L.Count-1 do
    begin
      Con := TConnection(L[I]);
      if (not Con.FFrom.Visible) or (not Con.FTo.Visible) then
        Continue;

      //Här vänds connectionen from=to, to=from
      //Detta för att algoritmen utgår ifrån att allting pekar nedåt, medans vi
      //vill att pilar pekar uppåt (desc pekar upp på basklass).
      if Con.FConnectStyle=csNormal then
      begin  //Inheritance vänds
        FromNode := Nodes[ Con.FTo.Tag ];
        ToNode := Nodes[ Con.FFrom.Tag ];
      end
      else
      begin  //Unit-Associationer samt Implements-interface behåller riktning
        FromNode := Nodes[ Con.FFrom.Tag ];
        ToNode := Nodes[ Con.FTo.Tag ];
      end;
      AddEdge(FromNode,ToNode);
    end;
  finally
    L.Free;
  end;
end;



//Skriver tillbaka layout till essconnectpanel
procedure TSugiyamaLayout.ApplyNodes;
var
  I : integer;
  Node : TNode;
begin
  for I := 0 to Nodes.Count-1 do
  begin
    Node := Nodes[I];
    if Node.IsDummy then
      Continue;
    Node.Control.Left := Node.X;
    Node.Control.Top := Node.Y;
  end;
end;


//Utför de olika stegen i layout-algoritmen
procedure TSugiyamaLayout.DoPhases;
begin
  //Placera noder i skikt
  LayeringPhase;
  //Sortera noder i varje skikt
  OrderingPhase;
  //Bestäm X och Y
  PositioningPhase;
end;



//'Skikta' diagrammet och tilldela varje nod ett skikt
procedure TSugiyamaLayout.LayeringPhase;
const
  //Max antal nodes i ett layer, används vid fördelning av zeronodes
  LayerMaxNodes = 16;
var
  I,J,MinC,MinI : integer;
  Node : TNode;
  ZeroNodes : TNodeList;
begin
  MakeAcyclic;
  InitialRanking;
  MakeProper;
  //Här skapas skikten baserat på nodernas rank
  Layers := TLayerList.Create;
  ZeroNodes := TNodeList.Create(False);
  try
    for I := 0 to Nodes.Count-1 do
    begin
      Node := Nodes[I];
      if Node.InEdges.Count + Node.OutEdges.Count=0 then
        ZeroNodes.Add(Node)
      else
      begin
        while Layers.Count<Nodes[I].Rank + 1 do
          Layers.Add( TNodeList.Create(False) );
        Layers[ Nodes[I].Rank ].Add( Nodes[I] );
      end;
    end;
    //Fördela noder utan edges på skikt med minst antal nodes
    for I:=0 to ZeroNodes.Count-1 do
    begin
      MinC := LayerMaxNodes;
      MinI := 0;
      for J := 0 to Layers.Count-1 do
        if Layers[J].Count<MinC then
        begin
          MinC := Layers[J].Count;
          MinI := J;
        end;
      if MinC>=LayerMaxNodes then
      begin
        //Om alla skikt har LayerMaxNodes antal noder så skapas nytt skikt
        Layers.Add( TNodeList.Create(False) );
        MinI := Layers.Count-1;
      end;
      Layers[MinI].Add(ZeroNodes[I]);
    end;
  finally
    ZeroNodes.Free;
  end;
  //Nu skall alla edges peka nedåt på skiktet direkt under
end;


destructor TSugiyamaLayout.Destroy;
begin
  if Assigned(Nodes) then Nodes.Free;
  if Assigned(Layers) then Layers.Free;
  inherited;
end;


procedure TSugiyamaLayout.AddEdge(const FromNode, ToNode: TNode);
begin
  FromNode.OutEdges.Add( TEdge.Create(FromNode,ToNode) );
  ToNode.InEdges.Add( TEdge.Create(FromNode,ToNode) );
end;




procedure TSugiyamaLayout.MakeAcyclic;
{
  Grafen får ej innehålla cykler, så dessa måste tas bort.

  En cykel knäcks genom att man vänder en edge i cykeln.

  DFS = Depth First Search.

  "strongly connected components"
    detta innebär noder där det finns en väg a->b och b<-a  (cykler)
    beräkna strongly components
      för varje component
        om det finns mer än en nod i component, vänd en edge
          den edge som har min( outdeg(v) ) max( indeg(v) + indeg(w) )
      loop till varje component innehåller endast en nod

  Mer info:
    http://www.ics.uci.edu/~eppstein/161/960215.html
    http://www.ics.uci.edu/~eppstein/161/960220.html
}
type
  TDfsStruct =
    record
      Visited,Removed : boolean;
      DfsNum,DfsLow : integer;
    end;
var
  DfsList : array of TDfsStruct;
  CurDfs,CycCount : integer;
  Path : TObjectList;
  I,Safety : integer;
  SuperNode : TNode;

  procedure InReverse(N : TNode; E : integer);
  var
    I : integer;
    ToNode : TNode;
  begin
    ToNode := N.OutEdges[E].ToNode;
    for I := 0 to ToNode.InEdges.Count-1 do
      if ToNode.InEdges[I].FromNode = N then
      begin
        ToNode.InEdges.Delete(I);
        N.OutEdges.Delete(E);
        AddEdge( ToNode, N );
        Break;
      end;
  end;

  procedure InVisit(N : TNode);
  var
    I,J,Score,BestScore,RevEdge : integer;
    W,V,RevNode : TNode;
    Cyc : TObjectList;
  begin
    Path.Add( N );
    with DfsList[ N.Id ] do
    begin
      DfsNum := CurDfs;
      DfsLow := CurDfs;
      Visited := True;
    end;
    Inc(CurDfs);
    //Promenera utedges rekursivt
    for I := 0 to N.OutEdges.Count-1 do
    begin
      W := N.OutEdges[I].ToNode;
      if not DfsList[ W.Id ].Removed then
      begin
        if not DfsList[ W.Id ].Visited then
        begin
          InVisit(W);
          DfsList[ N.Id ].DfsLow := Min( DfsList[ N.Id ].DfsLow , DfsList[ W.Id ].DfsLow );
        end
        else
          DfsList[ N.Id ].DfsLow := Min( DfsList[ N.Id ].DfsLow , DfsList[ W.Id ].DfsNum );
      end;
    end;
    //Kolla om det blev en cykel
    if DfsList[ N.Id ].DfsLow = DfsList[ N.Id ].DfsNum then
    begin
      Cyc := TObjectList.Create(False);
      repeat
        V := TNode(Path.Last);
        Path.Delete( Path.Count-1 );
        Cyc.Add( V );
        DfsList[ V.Id ].Removed := True;
      until V = N;
      if Cyc.Count>1 then
      begin //Riktig cykel funnen
        Inc(CycCount);
        BestScore := -1;
        RevEdge := 0;
        RevNode := TNode(Cyc[0]);
        for I :=0 to Cyc.Count-1 do
        begin //hitta den edge som har min( outdeg(v) ) max( indeg(v) + indeg(w) )
          V := TNode(Cyc[I]);
          for J := 0 to V.OutEdges.Count-1 do
            if Cyc.IndexOf( V.OutEdges[J].ToNode )>-1 then
            begin
              Score := V.InEdges.Count + V.OutEdges[J].ToNode.InEdges.Count - V.OutEdges.Count;
              if V.OutEdges.Count=1 then
                Inc(Score,50);
              if Score>BestScore then
              begin
                BestScore := Score;
                RevNode := V;
                RevEdge := J;
              end;
            end;
        end;
        InReverse(RevNode,RevEdge);
      end;
      Cyc.Free;
    end;
  end;

begin
  Path := TObjectList.Create(False);

  SuperNode := TNode.Create;
  for I := 0 to Nodes.Count-1 do
    SuperNode.OutEdges.Add( TEdge.Create(SuperNode,Nodes[I]) );
  SuperNode.Id := Nodes.Count;

  Safety := 0;
  repeat
    Path.Clear;
    DfsList := nil;
    SetLength(DfsList,Nodes.Count + 1);
    CurDfs := 0;
    CycCount := 0;
    InVisit(SuperNode);
    Inc(Safety);
    if Safety > 30 then
      raise Exception.Create('Layout failed.');
  until CycCount=0;

  SuperNode.Free;

  Path.Free;
end;




var
  //Global så att sorteringsfunktionen kan nå den
  _Labels : array of integer;

function TopoSortProc(Item1, Item2: Pointer): Integer;
begin
  if _Labels[ TNode(Item1).Id ] < _Labels[ TNode(Item2).Id ] then
    Result := -1
  else if _Labels[ TNode(Item1).Id ] = _Labels[ TNode(Item2).Id ] then
    Result:=0  //Lika
  else
    Result := 1;
end;

{
  Topological sort.
  Sortera så att alla beroenden pekar framåt i listan.
  Topological order:
    A numbering of the nodes of a directed acyclic graph such that every edge from a node
    numbered i to a node numbered j satisfies i<j.
}
procedure TSugiyamaLayout.TopoSort;
var
  Indeg : array of integer;
  S : TStack;
  I,NextLabel : integer;
  Node : TNode;
  Edge : TEdge;
begin
  SetLength(Indeg,Nodes.Count);
  _Labels := nil;
  SetLength(_Labels,Nodes.Count);

  S:=TStack.Create;
  try
    //init indeg med n.indeg
    //pusha noder med utan ingående edges
    for I:=0 to Nodes.Count-1 do
    begin
      Indeg[I] := Nodes[I].InEdges.Count;
      if Indeg[I]=0 then
        S.Push(Nodes[I]);
    end;

    if S.Count=0 then
      raise Exception.Create('empty layout or connection-cycles');

    NextLabel := 0;
    while S.Count>0 do
    begin
      Node := TNode(S.Pop);
      Inc(NextLabel);
      _Labels[Node.Id]:=NextLabel;
      for I:=0 to Node.OutEdges.Count-1 do
      begin
        Edge := Node.OutEdges[I];
        Dec(Indeg[ Edge.ToNode.Id ]);
        if (Indeg[ Edge.ToNode.Id ]=0) and (_Labels[Edge.ToNode.Id]=0) then
          S.Push( Edge.ToNode );
      end;
    end;

    //0 får ej finnas i _labels, mao alla noder måste ha gåtts igenom i loopen
    for I := 0 to High(_Labels) do
      if _Labels[I]=0 then
        raise Exception.Create('connection-cycles');

    //sortera nodes efter deras label
    Nodes.Sort(TopoSortProc);
    _Labels := nil;
    //sätt node.id till index i nodes-listan eftersom vi har bytt ordning
    for I:=0 to Nodes.Count-1 do
      Nodes[I].Id:=I;
  finally
    S.Free;
  end;
end;


procedure TSugiyamaLayout.InitialRanking;
{
    sortera nodes med topological sort

    nodes[0] har minst antal indeg, nodes[count] har flest
      setlength(rank,nodes.count)
      foreach nodes, n
        r = 0
        foreach nodes i n.inEdges, innode
          if rank[ innode ]>r then r= rank[ innode ] + 1
        rank[index]=r
}
var
  I,J,R,Temp : integer;
begin
  TopoSort;
  for I := 0 to Nodes.Count-1 do
  begin
    R := 0;
    for J := 0 to Nodes[I].InEdges.Count-1 do
    begin
      Temp := Nodes[I].InEdges[J].FromNode.Rank;
      if Temp>=R then
        R := Temp + 1;
    end;
    Nodes[I].Rank := R;
  end;
end;


procedure TSugiyamaLayout.SetYPositions;
const
  VSpacing = 40;
var
  Node : TNode;
  I,J : integer;
  Highest,Y : integer;
begin
  Y := 40;
  for I := 0 to Layers.Count-1 do
  begin
    //Placera alla noder i ett lager på samma y, öka y med högsta noden + spacing
    Highest := 0;
    for J := 0 to Layers[I].Count-1 do
    begin
      Node := Layers[I][J];
      Highest := Max(Node.H,Highest);
      Node.Y := Y;
    end;
    Inc(Y,Highest + VSpacing);
  end;
end;


procedure TSugiyamaLayout.SetXPositions;
const
  HSpacing = 20;
  MaxIter = 20;
var
  I,J,X,Z,OldZ,BailOut,RegStart,RegCount,MaxAmount,Amount : integer;
  Force,LastForce,RegForce : single;
  Layer : TNodeList;
  Node : TNode;
  Forces : array of single;

  function InCenter(const Node : TNode) : integer;
  begin
    Result := Node.X + Node.W div 2;
  end;

  function InForce(const Node : TNode) : single;
  var
    Sum : integer;
    I,Deg,CenterX : integer;
  begin
    Deg := Node.InEdges.Count + Node.OutEdges.Count;
    if Deg=0 then
    begin
      Result := 0;
      Exit;
    end;
    Sum := 0;
    CenterX := InCenter(Node);
    for I := 0 to Node.InEdges.Count-1 do
      Inc(Sum, InCenter(Node.InEdges[I].FromNode) - CenterX );
    for I := 0 to Node.OutEdges.Count-1 do
      Inc(Sum, InCenter(Node.OutEdges[I].ToNode) - CenterX );
    Inc(Z, Abs(Sum) );
    Result := (1 / Deg) * Sum;
  end;

begin
  //Initialisera X med hjälp av positionen i skiktet
  for I := 0 to Layers.Count-1 do
  begin
    Layer := Layers[I];
    X := HSpacing;
    for J := 0 to Layer.Count-1 do
    begin
      Node := Layer[J];
      Node.X := X;
      Inc(X,HSpacing + Node.W);
    end;
  end;

  BailOut := 0;
  OldZ := High(Integer);
  repeat
    Inc(BailOut);
    //Z är summan av skillnaden nod.x och nod.önskadx
    Z := 0;
    for I := 0 to Layers.Count-1 do
    begin
      Layer := Layers[I];

      SetLength(Forces,Layer.Count);
      for J := 0 to Layer.Count-1 do
        Forces[J] := InForce(Layer[J]);

      //Beräkna regioner av noder så att två grannar inte stoppar varandra
      RegStart:=0;
      while RegStart<Layer.Count do
      begin
        LastForce := Forces[RegStart];
        RegForce := LastForce;
        RegCount := 1;
        J := RegStart + 1;
        //"Touching" nodes med högre force hör till samma grupp
        while (J < Layer.Count) and (LastForce >= Forces[J]) and
          (Layer[J].X - (Layer[J-1].X + Layer[J-1].W) <= HSpacing) do
        begin
          LastForce := Forces[J];
          RegForce := RegForce + LastForce;
          Inc(J);
          Inc(RegCount);
        end;
        Force := 1/RegCount * RegForce;

        if Force<>0 then
        begin
          if Force<0 then
          begin
            //Move region left
            if RegStart=0 then
              MaxAmount := Layer[RegStart].X - HSpacing
            else //Får ej flytta över nod till vänster
              MaxAmount := Layer[RegStart].X - (Layer[RegStart-1].X + Layer[RegStart-1].W + HSpacing);
            Amount := -Min( Abs(Round(Force)) , MaxAmount );
          end
          else
          begin
            //Move region right
            if RegStart + RegCount = Layer.Count then
              MaxAmount := High(Integer)
            else //Får ej flytta över nod till höger
              MaxAmount := Layer[RegStart + RegCount].X -
                (Layer[ RegStart + RegCount - 1 ].X + Layer[ RegStart + RegCount - 1 ].W + HSpacing);
            Amount := Min( Round(Force) , MaxAmount );
          end;

          //Utför flytt av noder i regionen
          if Amount<>0 then
            for J := RegStart to RegStart + RegCount - 1 do
              Inc(Layer[J].X,Amount);
        end;

        //Flytta fram regionstart till noden efter denna region
        //Denna rad måste köras, Continue kan ej användas i koden ovan
        Inc(RegStart,RegCount)
      end; //Regions
    end; //Layers

    //Bryt ifall ingen förbättring sker
    //Om inte detta test görs så finns det risk att noder dras åt höger i all evighet
    if Z>=OldZ then
      Break;
    OldZ := Z;

  until (BailOut=MaxIter) or (Z=0);

end;


procedure TSugiyamaLayout.PositioningPhase;
begin
  SetYPositions;
  SetXPositions;
end;


//Lägg in dummy nodes så att varje edge har 1 i längd
procedure TSugiyamaLayout.MakeProper;
{
  O         O
  |   -->   |
  |         x
  |         |
  O         O
}
const
  DummyWidth = 200;
var
  I,J,K,Diff : integer;
  Node : TNode;
  Edge : TEdge;

  Path : array of TNode;

  function InMakeDummy : TNode;
  begin
    Result := TNode.Create;
    Result.IsDummy := True;
    //Dummys måste ha bredd för att inte puttas undan i PositionX
    Result.W := DummyWidth;
    Result.Id := Nodes.Count;
    Nodes.Add(Result);
  end;

begin
  for I := 0 to Nodes.Count-1 do
  begin
    Node := Nodes[I];
    for J := 0 to Node.OutEdges.Count-1 do
    begin
      Edge := Node.OutEdges[J];
      Diff := Edge.ToNode.Rank - Node.Rank;
      Assert(Diff>0);
      if Diff>1 then
      begin
        //Edge sträcker sig över fler än ett skikt, skapa dummy noder
        SetLength(Path,Diff-1);
        for K := 0 to High(Path) do
        begin
          Path[K] := InMakeDummy;
          Path[K].Rank := Node.Rank + K + 1;
          if K>0 then
            AddEdge(Path[K-1],Path[K]);
        end;
        for K := 0 to Edge.ToNode.InEdges.Count-1 do
          if Edge.ToNode.InEdges[K].FromNode=Node then
          begin
            Edge.ToNode.InEdges[K].FromNode := Path[High(Path)];
            Break;
          end;
        Path[High(Path)].OutEdges.Add( TEdge.Create(Path[High(Path)],Edge.ToNode) );
        Edge.ToNode := Path[0];
        Path[0].InEdges.Add( TEdge.Create(Node,Path[0]) );
      end;
    end;
  end;
end;



function WeightSortProc(Item1, Item2: Pointer): Integer;
begin
  if TNode(Item1).Weight < TNode(Item2).Weight then
    Result := -1
  else if TNode(Item1).Weight = TNode(Item2).Weight then
    Result:=0  //Lika
  else
    Result := 1;
end;

function OrderSortProc(Item1, Item2: Pointer): Integer;
begin
  if TNode(Item1).Order < TNode(Item2).Order then
    Result := -1
  else if TNode(Item1).Order = TNode(Item2).Order then
    Result:=0  //Lika
  else
    Result := 1;
end;

procedure TSugiyamaLayout.OrderingPhase;
const
  MaxIter = 20;
var
  I,J,BailOut,BestC : integer;
  BestO : array of integer;
  Layer : TNodeList;
  Node : TNode;

  function WeightPred(const Node : TNode) : single;
  var
    Sum,I : integer;
  begin
    Sum := 0;
    for I := 0 to Node.InEdges.Count-1 do
      Inc(Sum,Node.InEdges[I].FromNode.Order);
    if Node.InEdges.Count = 0 then
      Result := 0
    else
      Result := Sum / Node.InEdges.Count;
  end;

  function WeightSucc(const Node : TNode) : single;
  var
    Sum,I : integer;
  begin
    Sum := 0;
    for I := 0 to Node.OutEdges.Count-1 do
      Inc(Sum,Node.OutEdges[I].ToNode.Order);
    if Node.OutEdges.Count = 0 then
      Result := 0
    else
      Result := Sum / Node.OutEdges.Count;
  end;

  procedure InCheckCrossings;
  var
    I : integer;
  begin
    I := CalcCrossings;
    if I<BestC then
    begin
      BestC := I;
      for I := 0 to Nodes.Count-1 do
        BestO[I]:=Nodes[I].Order;
    end;
  end;

begin
  //**ge initial order, anropa remakeLayers;
  //**nu uppdaterar vi bara order
  for I := 0 to Layers.Count-1 do
    for J := 0 to Layers[I].Count-1 do
      Layers[I][J].Order := J;

  BailOut := 0;
  BestC := High(Integer);
  SetLength(BestO,Nodes.Count);
  repeat
    Inc(BailOut);
    //Gå nedåt och sortera om varje skikt baserat på order av noder i skiktet ovan
    for I := 1 to Layers.Count-1 do
    begin
      Layer := Layers[I];
      for J := 0 to Layer.Count-1 do
      begin
        Node := Layer[J];
        Node.Weight := WeightPred(Node);
      end;
      Layer.Sort( WeightSortProc );
      //Uppdatera order eftersom noder har bytt plats
      for J := 0 to Layer.Count-1 do Layer[J].Order := J;
    end;
    InCheckCrossings;
    if BestC=0 then
      Break;
    //Gå uppåt och sortera om varje skikt baserat på order av noder i skiktet nedanför
    for I := Layers.Count-2 downto 0 do
    begin
      Layer := Layers[I];
      for J := 0 to Layer.Count-1 do
      begin
        Node := Layer[J];
        Node.Weight := WeightSucc(Node);
      end;
      Layer.Sort( WeightSortProc );
      //Uppdatera order eftersom noder har bytt plats
      for J := 0 to Layer.Count-1 do Layer[J].Order := J;
    end;
    InCheckCrossings;
    //**ha flera tester för när vi skall avbryta, t.ex. ingen improvment sker
    //**nu körs alltid till maxiter
  until (BailOut>MaxIter) or (BestC=0);

  //Applicera den bästa ordningen
  for I := 0 to Nodes.Count-1 do
    Nodes[I].Order := BestO[I];
  for I := 0 to Layers.Count-1 do
    Layers[I].Sort( OrderSortProc );
end;


function TSugiyamaLayout.CalcCrossings: integer;
var
  I : integer;
begin
  Result := 0;
  if Layers.Count>1 then
    for I := 0 to Layers.Count-2 do
      Inc( Result , CalcCrossingsTwoLayers(Layers[I],Layers[I+1]) );
end;


function ToNodeCOrderSortProc(Item1, Item2: Pointer): Integer;
begin
  if TEdge(Item1).ToNode.COrder < TEdge(Item2).ToNode.COrder then
    Result := -1
  else if TEdge(Item1).ToNode.COrder = TEdge(Item2).ToNode.COrder then
    Result:=0  //Lika
  else
    Result := 1;
end;

function FromNodeCOrderSortProc(Item1, Item2: Pointer): Integer;
begin
  if TEdge(Item1).FromNode.COrder < TEdge(Item2).FromNode.COrder then
    Result := -1
  else if TEdge(Item1).FromNode.COrder = TEdge(Item2).FromNode.COrder then
    Result:=0  //Lika
  else
    Result := 1;
end;

function TSugiyamaLayout.CalcCrossingsTwoLayers(const Layer1, Layer2: TNodeList): integer;
var
  COrder,I,J,K : integer;
  K1,K2,K3 : integer;
  CNodes,UL,LL : TNodeList;
  Node : TNode;
begin
  Result := 0;
  COrder:=0;
  CNodes := TNodeList.Create(False);
  UL := TNodeList.Create(False);
  LL := TNodeList.Create(False);

  //Initialisera CNodes och Node.COrder
  for I :=0 to Max(Layer1.Count,Layer2.Count)-1 do
  begin
    Node:=nil;
    if I<Layer2.Count then
    begin
      Node := Layer2[I];
      Node.COrder:=COrder;
    end;
    CNodes.Add(Node);
    Inc(COrder);

    Node:=nil;
    if I<Layer1.Count then
    begin
      Node := Layer1[I];
      Node.COrder:=COrder;
    end;
    CNodes.Add(Node);
    Inc(COrder)
  end;

  {foreach cnodes, node
    if odd, sort outedges on tonode.corder
    if even, sort inedges on fromnode.corder}
  for I := 0 to CNodes.Count-1 do
  begin
    Node := CNodes[I];
    if Node=nil then
      Continue;
    if Odd(I) then
      Node.OutEdges.Sort( ToNodeCOrderSortProc )
    else
      Node.InEdges.Sort( FromNodeCOrderSortProc )
  end;

  for I := 0 to CNodes.Count-1 do
  begin
    Node := CNodes[I];
    if Node=nil then
      Continue;
    if Odd(I) then
    begin
      //Odd, upper layer
      K := UL.LastIndexOf(Node);
      if K<>-1 then
      begin
        K1:=0; K2:=0; K3:=0;
        for J := 0 to K do
        begin
          //Gå igenom alla aktiva endpoints i upperlayer
          if UL[J]=Node then
          begin
            Inc(K1);
            Inc(K3,K2);
            UL.Items[J]:=nil;
          end
          else
            Inc(K2);
        end;
        UL.Pack;
        //Öka antal crossings
        Inc(Result, K1 * LL.Count + K3);
      end;
      //Lägg till nya aktiva endpoints i lowerlayer
      for J := 0 to Node.OutEdges.Count-1 do
      begin
        //Ta bara med edges som pekar "åt höger" (högre corder), de andra hanteras av even
        if I < Node.OutEdges[J].ToNode.COrder then
          LL.Add( Node.OutEdges[J].ToNode );
      end;
    end
    else
    begin
      //Even, lower layer
      K := LL.LastIndexOf(Node);
      if K<>-1 then
      begin
        K1:=0; K2:=0; K3:=0;
        for J := 0 to K do
        begin
          //Gå igenom alla aktiva endpoints i upperlayer
          if LL[J]=Node then
          begin
            Inc(K1);
            Inc(K3,K2);
            LL.Items[J]:=nil;
          end
          else
            Inc(K2);
        end;
        LL.Pack;
        //Öka antal crossings
        Inc(Result, K1 * UL.Count + K3);
      end;
      //Lägg till nya aktiva endpoints i upperlayer
      for J := 0 to Node.InEdges.Count-1 do
      begin
        //Ta bara med edges som pekar "åt höger" (högre corder), de andra hanteras av odd
        if I < Node.InEdges[J].FromNode.COrder then
          UL.Add( Node.InEdges[J].FromNode );
      end;
    end;
  end;

  CNodes.Free;
  UL.Free;
  LL.Free;
end;




{ TEdge }

constructor TEdge.Create(const FromNode, ToNode: TNode);
begin
  Self.FromNode := FromNode;
  Self.ToNode := ToNode;
end;

{ TNode }

constructor TNode.Create;
begin
  InEdges := TEdgeList.Create;
  OutEdges := TEdgeList.Create;
end;

destructor TNode.Destroy;
begin
  InEdges.Free;
  OutEdges.Free;
  inherited;
end;

{ TNodeList }

function TNodeList.GetNode(Index: Integer): TNode;
begin
  Result := TNode(Get(Index));
end;

function TNodeList.LastIndexOf(const P: pointer): integer;
var
  I : integer;
begin
  Result := -1;
  for I := Count-1 downto 0 do
    if Get(I)=P then
    begin
      Result := I;
      Break;
    end;
end;

{ TEdgeList }

function TEdgeList.GetEdge(Index: Integer): TEdge;
begin
  Result := TEdge(Get(Index));
end;

{ TLayerList }

function TLayerList.GetLayer(Index: Integer): TNodeList;
begin
  Result := TNodeList(Get(Index));
end;

end.
