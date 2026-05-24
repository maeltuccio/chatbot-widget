# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

demo_account = Account.find_or_create_by!(owner_email: "demo@example.com") do |account|
  account.name = "Demo Account"
  account.plan = "demo"
end

demo_account.users.find_or_create_by!(email: ENV.fetch("ADMIN_EMAIL", "admin@example.com")) do |user|
  user.password = ENV.fetch("ADMIN_PASSWORD", "password123")
  user.password_confirmation = ENV.fetch("ADMIN_PASSWORD", "password123")
  user.role = "owner"
  user.platform_admin = true
end

platform_admin_emails = [
  ENV.fetch("ADMIN_EMAIL", "admin@example.com"),
  *ENV.fetch("PLATFORM_ADMIN_EMAILS", "").split(",").map(&:strip)
].reject(&:blank?).uniq

User.where(email: platform_admin_emails).update_all(platform_admin: true)

demo_agent = demo_account.agents.find_or_initialize_by(name: "Demo Agent")
demo_agent.assign_attributes(
  system_prompt: "Tu es un assistant support SaaS utile. Réponds clairement et poliment.",
  welcome_message: "Bonjour ! Comment puis-je vous aider aujourd'hui ?",
  tone: "amical",
  primary_goal: "Aider les visiteurs à comprendre le produit et répondre aux questions fréquentes.",
  active: true,
  widget_title: "Demo Agent",
  widget_primary_color: "#111827",
  widget_position: "bottom_right",
  widget_send_label: "Envoyer",
  widget_placeholder: "Écrivez votre message..."
)
demo_agent.save!

neuro_account = Account.find_or_create_by!(owner_email: "contact@epilepsycourses.example") do |account|
  account.name = "Epilepsy Courses"
  account.plan = "demo"
end
neuro_account.update!(name: "Epilepsy Courses")

neuro_account.users.find_or_create_by!(email: "epilepsy@example.com") do |user|
  user.password = ENV.fetch("ADMIN_PASSWORD", "password123")
  user.password_confirmation = ENV.fetch("ADMIN_PASSWORD", "password123")
  user.role = "owner"
end

neuro_agent = Agent.find_or_initialize_by(public_token: "neuroconsulting2026")
neuro_agent.account = neuro_account
neuro_agent.assign_attributes(
  name: "Epilepsy Courses Assistant",
  system_prompt: <<~PROMPT.squish,
    You are the Epilepsy Courses assistant for a medical education organization focused on neurology,
    epilepsy, EEG, SEEG, neurophysiology and multidisciplinary case preparation. You help visitors understand available
    courses, choose the right training, check dates, explain prerequisites, answer practical questions, and direct people
    to booking links. Be precise, calm, professional and useful.

    Keep answers short by default: 2 to 5 sentences, or 3 bullet points maximum. Do not list the full catalogue, full
    prerequisites, all prices, all dates, and all links unless the visitor explicitly asks for details or a comparison.
    Prefer asking one useful qualification question before recommending a course when the visitor's need is not clear.
    Good qualification questions include: their role, current experience level, topic of interest, preferred format,
    location, target month, and whether they register individually or for a hospital team.

    When recommending something, usually propose only the best next option and one booking link. If there are two clearly
    relevant choices, present them briefly and ask the visitor to choose. Use the knowledge base as your source of truth
    for courses, prices, policies, dates and booking links. If a visitor asks for medical diagnosis or patient-specific
    treatment advice, explain that you cannot provide medical advice and suggest contacting a qualified clinician.
    When information is missing, say so and offer to connect them with the coordination team.
  PROMPT
  welcome_message: "Bonjour, je suis l'assistant Epilepsy Courses. Je peux vous aider à choisir une formation, vérifier les dates ou préparer une réservation.",
  tone: "professional, warm, concise, medically literate",
  primary_goal: "Help clinicians and healthcare teams choose and book Epilepsy Courses training sessions.",
  active: true,
  widget_title: "Epilepsy Courses",
  widget_primary_color: "#137C89",
  widget_position: "bottom_right",
  widget_send_label: "Envoyer",
  widget_placeholder: "Posez votre question..."
)
neuro_agent.save!
neuro_agent.knowledge_sources.where("title LIKE ?", "Neuro Consulting -%").destroy_all

neuro_sources = {
  "Epilepsy Courses - presentation generale" => <<~CONTENT,
    Epilepsy Courses est un organisme fictif de formation médicale continue spécialisé dans la neurologie clinique, l'épileptologie, l'EEG, la SEEG et la préparation de dossiers complexes en réunion multidisciplinaire.

    Mission: aider les neurologues, neurochirurgiens, internes, techniciens EEG seniors et équipes hospitalières à consolider leurs compétences pratiques grâce à des formations courtes, structurées et orientées cas cliniques.

    Publics concernés: neurologues, neurochirurgiens, médecins MPR avec activité neuro, internes en neurologie ou neurochirurgie à partir de la troisième année, techniciens EEG expérimentés, coordinateurs de parcours épilepsie, infirmiers de pratique avancée en neurologie.

    L'assistant doit présenter Epilepsy Courses comme une équipe de formation et conseil. Il ne doit jamais prétendre remplacer un avis médical. Pour toute question patient, diagnostic, traitement ou urgence, il doit recommander de consulter l'équipe médicale référente ou les services d'urgence.

    Positionnement: formations pratiques, petits groupes, cas réels anonymisés, documentation claire, échanges avec les formateurs, supports remis après la session. Les sessions sont conçues pour être directement utiles en pratique clinique.

    Contact coordination: coordination@epilepsycourses.example. Téléphone fictif: +33 1 84 88 40 12. Horaires de réponse: lundi au vendredi, 9h00-18h00, heure de Paris.

    Lien principal de réservation: https://epilepsycourses.example/reserver. Lien catalogue complet: https://epilepsycourses.example/formations. Lien demande de devis institutionnel: https://epilepsycourses.example/devis-hopital.
  CONTENT

  "Epilepsy Courses - catalogue formations 2026" => <<~CONTENT,
    Catalogue des formations Epilepsy Courses 2026.

    Formation 1: Atelier SEEG avance - de l'hypothese anatomo-clinique a la strategie d'implantation.
    Objectif: apprendre à structurer une hypothèse SEEG, sélectionner les réseaux à explorer, argumenter les trajectoires et préparer une discussion de RCP.
    Public: neurologues, neurochirurgiens, épileptologues, internes avancés.
    Niveau: avancé. Prérequis: bases solides en épileptologie, lecture EEG et imagerie cérébrale; expérience ou exposition à des dossiers préchirurgicaux.
    Durée: 2 jours, 14 heures. Format: présentiel, groupe de 18 participants maximum.
    Prix individuel fictif: 1 250 EUR HT. Prix institutionnel à partir de 4 participants: 980 EUR HT par personne.
    Dates 2026: 18-19 juin 2026 à Paris; 12-13 novembre 2026 à Lyon.
    Lien réservation: https://epilepsycourses.example/reserver/seeg-avance-2026.

    Formation 2: Lecture EEG intensive - pièges, patterns et raisonnement clinique.
    Objectif: progresser rapidement sur l'analyse EEG adulte, reconnaître les patterns critiques, éviter les faux positifs et relier les tracés au contexte clinique.
    Public: neurologues, internes, techniciens EEG seniors.
    Niveau: intermédiaire. Prérequis: connaître les bases du montage EEG, rythmes physiologiques et anomalies épileptiformes courantes.
    Durée: 1 jour, 7 heures. Format: présentiel ou classe virtuelle interactive.
    Prix individuel fictif: 590 EUR HT. Prix institutionnel à partir de 6 participants: 490 EUR HT par personne.
    Dates 2026: 3 juillet 2026 en classe virtuelle; 9 octobre 2026 à Marseille; 4 décembre 2026 en classe virtuelle.
    Lien réservation: https://epilepsycourses.example/reserver/eeg-intensif-2026.

    Formation 3: RCP epilepsie complexe - préparer, présenter et décider.
    Objectif: aider les équipes à structurer les dossiers de RCP, synthétiser les données cliniques, EEG, imagerie, neuropsychologie et discuter les options thérapeutiques.
    Public: équipes hospitalières, neurologues, neurochirurgiens, coordinateurs de parcours.
    Niveau: intermédiaire à avancé.
    Durée: 1 jour, 7 heures. Format: atelier présentiel en petit groupe.
    Prix individuel fictif: 720 EUR HT. Prix équipe sur devis.
    Dates 2026: 22 septembre 2026 à Lille; 8 décembre 2026 à Paris.
    Lien réservation: https://epilepsycourses.example/reserver/rcp-epilepsie-2026.

    Formation 4: Parcours sur mesure pour service hospitalier.
    Objectif: construire un programme adapté à un service: audit pédagogique, sélection de cas, atelier EEG, atelier SEEG, simulation RCP et recommandations d'organisation.
    Public: CHU, cliniques spécialisées, réseaux territoriaux.
    Durée: 1 à 3 jours selon besoin. Format: intra-établissement ou hybride.
    Prix fictif: devis personnalisé à partir de 4 800 EUR HT.
    Disponibilités 2026: créneaux sur demande en janvier, mars, mai, septembre et novembre 2026.
    Lien demande: https://epilepsycourses.example/devis-hopital.
  CONTENT

  "Epilepsy Courses - reservation paiement annulation" => <<~CONTENT,
    Processus de réservation Epilepsy Courses.

    Pour réserver une formation individuelle, envoyer le visiteur vers https://epilepsycourses.example/reserver. Pour une formation précise, utiliser le lien de réservation correspondant au catalogue.

    Étapes de réservation: choisir la formation, choisir la date, compléter les informations participant, indiquer le mode de financement, valider la demande. Une confirmation automatique est envoyée par email sous quelques minutes. La convention de formation fictive est envoyée sous 2 jours ouvrés.

    Paiement: carte bancaire, virement bancaire ou prise en charge institutionnelle. Les établissements peuvent demander un bon de commande. Les prix affichés sont fictifs et hors taxes.

    Documents fournis: programme détaillé, convocation, informations pratiques, facture ou convention, attestation de présence, support pédagogique PDF après la formation.

    Politique d'annulation: annulation gratuite jusqu'à 21 jours calendaires avant la session. Entre 20 et 8 jours avant la session, 50% du montant est dû. À 7 jours ou moins, la totalité est due sauf remplacement par un autre participant du même établissement.

    Report: un report gratuit est possible jusqu'à 14 jours avant la session, sous réserve de places disponibles. En cas d'annulation par Epilepsy Courses, le participant peut choisir un remboursement complet ou un report sur une nouvelle date.

    Accessibilité: les participants ayant des besoins spécifiques peuvent écrire à coordination@epilepsycourses.example au moins 30 jours avant la session pour organiser les adaptations raisonnables.

    Facturation et devis: pour un devis institutionnel, utiliser https://epilepsycourses.example/devis-hopital ou écrire à coordination@epilepsycourses.example avec le nom de l'établissement, le nombre de participants, la formation souhaitée et les dates visées.
  CONTENT

  "Epilepsy Courses - aide au choix formation" => <<~CONTENT,
    Guide d'orientation pour recommander la bonne formation.

    Style de réponse attendu: l'assistant doit répondre court. Il ne doit pas réciter tout le catalogue. Il doit d'abord comprendre le besoin si la demande est vague. Réponse idéale quand la demande est vague: une phrase d'accueil puis une question utile. Exemple: "Bien sûr. Vous cherchez plutôt une formation EEG, SEEG, ou une aide à la préparation de dossiers en RCP ?" Exemple pour une demande de dates: "Je peux vous aider. Vous avez une préférence pour le présentiel ou la classe virtuelle ?"

    Quand l'utilisateur demande "quelles sont les formations", "je veux une formation", "vous proposez quoi", "je veux réserver" sans précision: poser une seule question de qualification avant de détailler. Ne pas donner toutes les dates immédiatement.

    Quand l'utilisateur demande explicitement une comparaison ou tous les détails: donner une réponse structurée mais courte, maximum 2 options à la fois, avec les informations les plus utiles: nom, date, format, prix, lien. Proposer d'envoyer le détail complet ensuite.

    Quand l'utilisateur demande la dernière formation, prochaine formation, ou une date précise: répondre avec uniquement la session pertinente et le lien, puis demander s'il veut réserver ou vérifier les prérequis.

    Si le visiteur parle de SEEG, exploration invasive, hypothèse anatomo-clinique, implantation, trajectoires, réseau épileptogène, chirurgie de l'épilepsie ou dossier préchirurgical: recommander l'Atelier SEEG avancé. Mentionner les dates 18-19 juin 2026 à Paris et 12-13 novembre 2026 à Lyon. Lien: https://epilepsycourses.example/reserver/seeg-avance-2026.

    Si le visiteur veut progresser en EEG, lecture de tracés, patterns, anomalies épileptiformes, artefacts, faux positifs ou formation technicien EEG: recommander Lecture EEG intensive. Mentionner les dates 3 juillet 2026 en classe virtuelle, 9 octobre 2026 à Marseille et 4 décembre 2026 en classe virtuelle. Lien: https://epilepsycourses.example/reserver/eeg-intensif-2026.

    Si le visiteur évoque une réunion de concertation pluridisciplinaire, un staff, une synthèse de dossier, une décision thérapeutique, une organisation de parcours ou des cas complexes: recommander RCP épilepsie complexe. Mentionner les dates 22 septembre 2026 à Lille et 8 décembre 2026 à Paris. Lien: https://epilepsycourses.example/reserver/rcp-epilepsie-2026.

    Si le visiteur représente un service hospitalier, une équipe complète, un CHU, une clinique ou souhaite une formation interne: recommander le Parcours sur mesure pour service hospitalier. Demander le nombre de participants, les objectifs, le niveau moyen, les dates possibles et renvoyer vers https://epilepsycourses.example/devis-hopital.

    Si le visiteur ne sait pas quoi choisir, poser trois questions: son métier, son niveau d'expérience, et le problème principal à résoudre. Ensuite proposer une option claire et un lien.

    Si le visiteur demande "quelle formation est la plus adaptée pour débuter", proposer Lecture EEG intensive si son sujet est EEG, ou RCP épilepsie complexe si son sujet est l'organisation des dossiers. L'Atelier SEEG avancé n'est pas recommandé comme première formation sans expérience préchirurgicale.
  CONTENT

  "Epilepsy Courses - FAQ pratique" => <<~CONTENT,
    FAQ Epilepsy Courses.

    Les formations sont-elles certifiantes? Epilepsy Courses remet une attestation de présence et un certificat interne de participation. Il ne s'agit pas d'un diplôme universitaire.

    Les cas cliniques sont-ils réels? Oui, les formations utilisent des cas réels anonymisés, adaptés à un objectif pédagogique. Aucune donnée patient identifiable n'est utilisée.

    Peut-on venir sans expérience SEEG? Pour l'Atelier SEEG avancé, une expérience en épileptologie et dossiers préchirurgicaux est fortement recommandée. Pour débuter, orienter vers Lecture EEG intensive ou RCP épilepsie complexe selon le besoin.

    Les formations sont-elles en français? Oui, la majorité des sessions 2026 sont en français. Des supports peuvent inclure des termes anglais médicaux. Une session anglophone peut être organisée sur demande pour les groupes.

    Combien de participants par session? Les ateliers pratiques sont limités à 18 participants. La Lecture EEG intensive en classe virtuelle accepte jusqu'à 28 participants. Les formations intra-établissement dépendent du format choisi.

    Y a-t-il des supports après la formation? Oui, un PDF pédagogique, une bibliographie courte et des fiches méthode sont envoyés après la session. Les enregistrements vidéo ne sont pas inclus par défaut.

    Peut-on poser des questions avant la session? Oui. Les participants peuvent envoyer leurs objectifs et questions à coordination@epilepsycourses.example. Pour des cas cliniques, il faut vérifier les règles locales de confidentialité et anonymiser strictement les données.

    Où ont lieu les formations? Les lieux fictifs 2026 sont Paris, Lyon, Marseille, Lille et classe virtuelle. L'adresse exacte est envoyée avec la convocation.

    Y a-t-il une restauration? Pour les formations présentiels d'une journée complète ou plus, café d'accueil et déjeuner léger sont inclus, sauf mention contraire sur la convocation.

    Comment réserver? Utiliser https://epilepsycourses.example/reserver ou le lien direct de la formation. Pour les groupes et hôpitaux, utiliser https://epilepsycourses.example/devis-hopital.
  CONTENT
}

neuro_sources.each do |title, raw_content|
  source = neuro_agent.knowledge_sources.find_or_initialize_by(title: title)
  source.assign_attributes(
    source_type: "manual",
    status: "draft",
    raw_content: raw_content
  )
  source.save!
  source.rebuild_chunks!
end
