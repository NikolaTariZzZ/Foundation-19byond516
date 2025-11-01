// Простая система логов банов для Baystation12

// Глобальная переменная для webhook URL
GLOBAL_VAR_INIT(ban_webhook_url, null)

// Инициализация при старте мира
/world/New()
    ..()
    spawn(10)
        setup_ban_webhook()

/proc/setup_ban_webhook()
    // Читаем конфиг вручную, так как config может быть не доступен
    var/config_file = file("config/config.txt")
    if(config_file)
        var/config_text = file2text(config_file)
        var/regex/R = regex("discord_webhook_bans\\s*=\\s*\"([^\"]+)\"", "i")
        if(R.Find(config_text))
            GLOB.ban_webhook_url = R.group[1]
            world.log << "Ban webhook URL loaded: [GLOB.ban_webhook_url]"

/proc/log_ban_to_discord(banned_ckey, admin_ckey, reason, duration, ban_type = "Игра")
    if(!GLOB.ban_webhook_url)
        world.log << "Ban webhook: No URL configured"
        return
    
    // Создаем простое текстовое сообщение вместо embed
    var/message = "🚫 **БАН ВЫДАН**\n"
    message += "👤 **Игрок:** [banned_ckey || "Неизвестно"]\n"
    message += "🛡️ **Администратор:** [admin_ckey || "Сервер"]\n" 
    message += "📝 **Причина:** [reason || "Не указана"]\n"
    
    if(duration && duration > 0)
        message += "⏰ **Длительность:** [duration] минут\n"
    else
        message += "⏰ **Длительность:** Перманентно\n"
    
    message += "🔧 **Тип:** [ban_type]\n"
    message += "🕐 **Время:** [time2text(world.realtime, "YYYY-MM-DD HH:MM:SS")]"
    
    // Простая отправка через world.Export
    var/url = "[GLOB.ban_webhook_url]?wait=1"
    var/data = "content=[url_encode(message)]"
    
    world.log << "Sending ban webhook: [banned_ckey]"
    spawn(0)
        world.Export("[url]", list("content" = message))

// Тестовый верб для проверки
/client/proc/test_ban_webhook()
    set name = "Test Ban Webhook"
    set category = "Admin.Debug"
    
    if(!check_rights(R_BAN))
        return
    
    log_ban_to_discord(
        "TestPlayer", 
        usr.ckey, 
        "Тестовый бан для проверки webhook", 
        60, 
        "Тест"
    )
    to_chat(usr, "<span class='adminnotice'>Тестовый бан отправлен в Discord</span>")

// Верб для ручного логирования бана
/client/proc/manual_log_ban()
    set name = "Manual Log Ban"
    set category = "Admin.Debug"
    
    if(!check_rights(R_BAN))
        return
    
    var/banned_ckey = input("Ключ забаненного игрока:", "Лог бана") as text|null
    if(!banned_ckey)
        return
        
    var/reason = input("Причина бана:", "Лог бана") as text|null
    var/duration = input("Длительность в минутах (0 для перманента):", "Лог бана") as num|null
    
    log_ban_to_discord(
        banned_ckey,
        usr.ckey,
        reason || "Не указана",
        duration || 0,
        "Ручной лог"
    )
    to_chat(usr, "<span class='adminnotice'>Бан [banned_ckey] записан в Discord</span>")
