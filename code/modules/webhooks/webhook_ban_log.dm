#define WEBHOOK_BAN_PLAYER_JOIN "player_join"
#define WEBHOOK_BAN_PLAYER_LEAVE "player_leave" 
#define WEBHOOK_BAN_NEW "ban_new"
#define WEBHOOK_BAN_APPEAL "ban_appeal"
#define WEBHOOK_BAN_REMOVED "ban_removed"

// Ban webhook structure
/datum/webhook_ban_log
	var/player_ckey
	var/admin_ckey
	var/reason
	var/duration
	var/ban_type
	var/timestamp

/datum/webhook_ban/New(ckey, admin, ban_reason, ban_duration, type)
	player_ckey = ckey
	admin_ckey = admin
	reason = ban_reason
	duration = ban_duration
	ban_type = type
	timestamp = SQLtime()
    ban_id = ban_id
