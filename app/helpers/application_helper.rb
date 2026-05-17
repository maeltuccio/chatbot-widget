module ApplicationHelper
  def agent_status_label(agent)
    agent.active? ? "Actif" : "Inactif"
  end

  def widget_status_label(agent)
    agent.active? ? "En ligne" : "Désactivé"
  end

  def yes_no_label(value)
    value ? "Oui" : "Non"
  end

  def source_status_label(status)
    {
      "draft" => "Brouillon",
      "processing" => "En traitement",
      "ready" => "Prêt",
      "failed" => "Échec"
    }.fetch(status, status)
  end

  def source_type_label(source_type)
    {
      "manual" => "Manuel",
      "website" => "Site web",
      "document" => "Document"
    }.fetch(source_type, source_type)
  end

  def connection_status_label(status)
    {
      "connected" => "Connecté",
      "configured" => "Configuré",
      "failed" => "Échec"
    }.fetch(status, status)
  end

  def widget_position_options
    [["En bas à droite", "bottom_right"], ["En bas à gauche", "bottom_left"]]
  end

  def widget_theme_label(theme)
    {
      "glass" => "Verre",
      "light" => "Clair",
      "dark" => "Sombre"
    }.fetch(theme, theme)
  end

  def message_role_label(role)
    {
      "visitor" => "Visiteur",
      "assistant" => "Assistant"
    }.fetch(role, role)
  end
end
