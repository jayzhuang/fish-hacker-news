set BASE_URL 'https://hacker-news.firebaseio.com/v0'

function __n_or_default
    if set -q argv[1]
        echo $argv[1]
    else
        echo 10
    end
end

# Helpers for setting and unsetting colors on output.
function __c
    set_color $argv
end
function __nc
    set_color normal
end

function __print_stories
    set i 1
    for id in $argv
        set -l resp (curl -s "$BASE_URL/item/$id.json")
        set -l title (echo $resp | jq -r '.title')
        set -l url (echo $resp | jq -r '.url')
        echo [$i] (__c -o green)$title(__nc) (__c blue)$url(__nc)
        set i (math $i+1)
    end
    echo
    echo "To view page 1 through "(math $i-1)", use"
    echo (__c -o blue)"hn view [#]"(__nc) "to view in CLI"
    echo (__c -o blue)"hn open [#]"(__nc) "to open in browser"
end

function __top_hn_stories
    set N (__n_or_default $argv[1])
    echo (__c -o red)"== Top $N Hacker News Stories =="(__nc)
    set top_stories (curl -s "$BASE_URL/topstories.json" | jq -r '.[]')
    # Persist IDs across sessions so read an open can use them.
    # TODO(jayzhuang): look into why `set -e` is necessary, otherwise
    # __print_stories gets null
    set -e HN_STORY_IDS
    set -U HN_STORY_IDS $top_stories[1..$N]
    __print_stories $HN_STORY_IDS
end

function __best_hn_stories
    set N (__n_or_default $argv[1])
    echo (__c -o red)"== Best $N Hacker News Stories =="(__nc)
    set best_stories (curl -s "$BASE_URL/beststories.json" | jq -r '.[]')
    # Persist IDs across sessions so read an open can use them.
    set -e HN_STORY_IDS
    set -U HN_STORY_IDS $best_stories[1..$N]
    __print_stories $HN_STORY_IDS
end

function __nth_id
    set ids (string split ' ' $HN_STORY_IDS)
    echo $ids[$argv[1]]
end

function __read_hn_story
    set id (__nth_id $argv[1])
    w3m -dump (curl -s "$BASE_URL/item/$id.json" | jq -r '.url') | less
end

function __open_hn_story
    set id (__nth_id $argv[1])
    open (curl -s "$BASE_URL/item/$id.json" | jq -r '.url')
end

function hn -d 'Hacker news CLI client in fish'
    set subcommand $argv[1]
    switch $subcommand
        case 'top'
            __top_hn_stories $argv[2]
        case 'best'
            __best_hn_stories $argv[2]
        case 'view'
            __read_hn_story $argv[2]
        case 'open'
            __open_hn_story $argv[2]
        case '*'
            echo "unknown subcommand $subcommand"
    end
end
