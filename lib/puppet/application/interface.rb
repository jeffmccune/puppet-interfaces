require 'puppet/application'

class Puppet::Application::Interface < Puppet::Application

  should_parse_config
  run_mode :agent

  option("--debug", "-d") do |arg|
    Puppet::Util::Log.level = :debug
  end

  option("--verbose", "-v") do
    Puppet::Util::Log.level = :info
  end

  def list(*arguments)
    if arguments.empty?
      arguments = %w{terminuses actions}
    end
    indirections.each do |ind|
      str = "#{ind}:\n"
      if arguments.include?("terminuses")
        begin
          terms = terminus_classes(ind.to_sym)
          str << "\tTerminuses: #{terms.join(", ")}\n"
        rescue => detail
          $stderr.puts "Could not load terminuses for #{ind}: #{detail}"
        end
      end

      if arguments.include?("actions")
        begin
          actions = actions(ind.to_sym)
          str << "\tActions: #{actions.join(", ")}\n"
        rescue => detail
          $stderr.puts "Could not load actions for #{ind}: #{detail}"
        end
      end

      print str
    end
    exit(0)
  end

  attr_accessor :verb, :name, :arguments

  def main
    # Call the method associated with the provided action (e.g., 'find').
    send(verb, *arguments)
  end

  def setup
    Puppet::Util::Log.newdestination :console

    load_applications # Call this to load all of the apps

    @verb, @arguments = command_line.args
    @arguments ||= []

    validate
  end

  def validate
    unless verb
      raise "You must specify 'find', 'search', 'save', or 'destroy' as a verb; 'save' probably does not work right now"
    end

    unless respond_to?(verb)
      raise "Command '#{verb}' not found for 'interface'"
    end
  end

  def indirections
      Puppet::Indirector::Indirection.instances.collect { |t| t.to_s }.sort
  end

  def terminus_classes(indirection)
      Puppet::Indirector::Terminus.terminus_classes(indirection).collect { |t| t.to_s }.sort
  end

  def actions(indirection)
    return [] unless interface = Puppet::Interface.interface(indirection)
    interface.load_actions
    return interface.actions.sort { |a,b| a.to_s <=> b.to_s }
  end

  def load_applications
    command_line.available_subcommands.each do |app|
      command_line.require_application app
    end
  end
end

