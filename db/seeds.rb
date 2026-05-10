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

demo_agent = demo_account.agents.find_or_initialize_by(name: "Demo Agent")
demo_agent.assign_attributes(
  system_prompt: "You are a helpful SaaS support assistant. Answer clearly and politely.",
  welcome_message: "Hi! How can I help you today?",
  tone: "friendly",
  primary_goal: "Help visitors understand the product and answer common questions.",
  active: true,
  widget_title: "Demo Agent",
  widget_primary_color: "#111827",
  widget_position: "bottom_right",
  widget_send_label: "Send",
  widget_placeholder: "Type your message..."
)
demo_agent.save!
