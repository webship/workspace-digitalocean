Feature: The DigitalOcean plugin on a project row
  Once the plugin is activated and installed, every site row carries the DIGITALOCEAN menu, and the Plugins
  page lists the plugin with its four steps.

  Scenario: A site row offers the DIGITALOCEAN menu, captioned with its link state
    Given I am on "/dev"
     Then the element ".act-menu-digitalocean" should be displayed
      And I should see "DIGITALOCEAN"
      And the element ".act-menu-digitalocean + .act-status" should be displayed

  Scenario: An unlinked project's menu opens and says how to link it
    Given I am on "/dev"
      And I click on the element ".project-row .act-menu-digitalocean button"
     Then ".uk-dropdown.uk-open" should be visible
      And I should see "Not linked to DigitalOcean"

  Scenario: The plugin is listed on the Plugins page
    Given I am on "/settings/plugins"
     Then I should see "DigitalOcean"
      And I should see "@webship/workspace-digitalocean"
