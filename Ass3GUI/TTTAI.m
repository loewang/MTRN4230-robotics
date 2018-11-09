function bestMove = TTTAI(boardState)

    % human
    human = 'X';

    % ai
    ai = 'O';

    % example board state
    boardState = {'O',2,'X',4,'O',6,'X','O','X'};
    % empty board: boardState = {1,2,3,4,5,6,7,8,9};

    
    emptySpots = findEmptyIndexes(boardState);
    
    % Find if winning move for ai exists
    for i = 1:length(emptySpots)
        boardState{emptySpots(i)} = ai;
        aiWin = winning(boardState,ai);
        boardState{emptySpots(i)} = emptySpots(i);
        if aiWin
            bestMove = emptySpots(i);
            return;
        end
    end
    
    % Find if winning move for human needs to be denied
    for i = 1:length(emptySpots)
        boardState{emptySpots(i)} = human;
        humanWin = winning(boardState,human);
        boardState{emptySpots(i)} = emptySpots(i);
        if humanWin
            bestMove = emptySpots(i);
            return;
        end
    end
    
    % else hard code behaviour
    
    % if empty board
    if length(emptySpots) == 9
        % always go bottom left corner
        bestMove = 7;
        return;
    end
    
    % after 1st human move
    if length(emptySpots) == 7
        
        % if human move was edges, index = 2,4,6,8
        edges = [2 4 6 8];
        if sum(ismember(edges,emptySpots)) ~= 4 % i.e. one of the four edges is occupied by human
            bestMove = 5; % always go centre, automatic win after if it was far edge
            return;
        end
        
        % if human move was adjacent corners, index = 1,9
        if ismember(1,emptySpots) == 0 
            bestMove = 9; % always go opposite corner;
            return;
        elseif ismember(9,emptySpots) == 0 
            bestMove = 1;
            return;
        end
        
        % if human move was far corner, index = 3;
        if ismember(3,emptySpots) == 0
           bestMove = 1; % always go top left corner, either adjacent corner works though
           return;
        end
        
        % if human move was centre, index = 5
        if ismember(5,emptySpots) == 0
            bestMove = 3; % best chance is far corner, automatic win if human picks either adjacent corners
            % otherwise, win checking will play out the game into a tie
            return;
        end

    end
    
    % after 2nd human move
    if length(emptySpots) == 5
        
        % if 1st human move was close edge, go opposite close edge
        if emptySpots == [1 2 5 7 8]
            bestMove = 8; 
            return;
        elseif emptySpots == [1 2 4 5 7]
            bestMove = 4;
            return;
        end
        
        % if 1st human move was a corner, go last corner
        corners = [1 3 7 9];
        lastCorner = corners(ismember(corners,emptySpots) == 1);
        bestMove = lastCorner;
        return;
        
    end    
    
end

function emptyIndexes = findEmptyIndexes(board)
    
    emptyIndexes = [];

    for i = 1:length(board)
       if  board{i} ~= 'O' && board{i} ~= 'X'
          emptyIndexes(end+1) = i; 
       end 
    end
end

function win = winning(board, player)
    if((board{1} == player && board{2} == player && board{3} == player) || ...
       (board{4} == player && board{5} == player && board{6} == player) || ...
       (board{7} == player && board{8} == player && board{9} == player) || ...
       (board{1} == player && board{4} == player && board{7} == player) || ...
       (board{2} == player && board{5} == player && board{8} == player) || ...
       (board{3} == player && board{6} == player && board{9} == player) || ...
       (board{1} == player && board{5} == player && board{9} == player) || ...
       (board{3} == player && board{5} == player && board{7} == player) )
        
        win = 1;
    else 
        win = 0;
    end
end
