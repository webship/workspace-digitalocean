Feature: The DigitalOcean plugin on a project row
  Once the plugin is activated and installed, every site row carries the DIGITALOCEAN menu, and the Plugins
  page lists the plugin with its four steps.

  @needs-project-dev
  Scenario: A site row offers the DIGITALOCEAN menu, captioned with its link state
    Given I am on "/dev"
     Then the element ".act-menu-digitalocean" should be displayed
      And I should see "DIGITALOCEAN"
      And the element ".act-menu-digitalocean + .act-status" should be displayed

  @needs-project-dev
  Scenario: An unlinked project's menu opens and says how to link it
    Given I am on "/dev"
      And I click on the element ".project-row .act-menu-digitalocean button"
     Then ".uk-dropdown.uk-open" should be visible
      And I should see "Not linked to DigitalOcean"

  # The Plugins page names each plugin; the package is on the plugin's own page (the row shows it on hover only).
  Scenario: The plugin is listed on the Plugins page, and its own page names its package
    Given I am on "/settings/plugins"
     Then I should see "DigitalOcean"
     When I go to "/settings/plugin/digitalocean"
     Then I should see "@webship.co/workspace-digitalocean"

  # The AI folders are searched by name: with every plugin on, a folder lists more than one page of items.
  Scenario: The AI Agents folder lists the agent the plugin ships
    Given I am on "/ai-agents?q=digitalocean-deployer"
     Then I should see "digitalocean-deployer"

  Scenario: The AI Skills folder lists the skill the plugin ships
    Given I am on "/ai-skills?q=digitalocean-hosting"
     Then I should see "digitalocean-hosting"

  Scenario: The AI Commands folder lists the command the plugin ships
    Given I am on "/ai-commands?q=digitalocean-status"
     Then I should see "digitalocean-status"

  Scenario: The AI Prompts folder lists the prompt the plugin ships
    Given I am on "/ai-prompts?q=digitalocean-test-then-deploy"
     Then I should see "digitalocean-test-then-deploy"
