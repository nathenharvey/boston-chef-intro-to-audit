# Audit a Linux node for compliance

^ Whether you must comply with regulatory frameworks such as PCI, HIPAA, or Dodd-Frank, or you have internal company standards you must meet, adhering to your compliance policies helps you deliver safe, secure applications and services.

---

# Compliance

- Analyze
- Specify
- Test
- Certify

^ Meeting the challenge of compliance requires both planning and action, and can be broken down into these stages.

---

# Analyze

### Be clear about your compliance requirements and the desired state of your infrastructure.

---

# Specify
### Translate your desired state into a formal language that precisely specifies your requirements.

---

# Test

### Verify whether the actual state of your infrastructure meets the desired state.

^ Automated tests scale better than manual tests, and can be written even before a new software system or service is developed to provide a clear set of standards that must be met.

---

# Certify
### Although not always required, many compliance processes require a final human sign off.

^ The better your tests, the shorter the certification step can be.

---

## Think about your current compliance and audit process.

### How can you _prove_ that the actual state of your infrastructure meets the desired state?

![](http://deckset-assets.s3-website-us-east-1.amazonaws.com/colnago2.jpg)

^ With Chef, you write code to describe the desired state of your infrastructure. When Chef runs, it applies the configuration only when the current state differs from the desired state. This approach is called test and repair.

^ But compliance is not only about what's on the system, but what's not on the system. For example, a database server in production might have certain requirements around which users can access data and which ports are open, but it may also be required to disallow access to services such as FTP and Telnet.

---

# [fit] How can Chef make this better?

^ Chef's audit mode enables you to write controls, or automated test code, that check whether your requirements are being met. Like your infrastructure code, you can collaborate on, version, and deploy these controls as part of your production pipeline. Because the tests are automated, you can apply them repeatedly, giving you increased confidence that even minor changes won't break any compliance rules.

---

# Chef Infrastructure
![inline 100%](img/analytics-overview.png)

^ You can run audit mode alone or you can use it along with Chef Analytics. If you use Chef Analytics with audit mode, you can write Chef Analytics rules that automatically notify the relevant people and services if an audit run exposes a problem

---

# Audit mode also acts as a form of documentation.

### The audit tests formally define the requirements, and from the output you can generate reports that prove whether the actual state of your infrastructure meets those requirements.

---

# You can use audit mode in environments that are not managed by Chef.

### You can start by using audit mode in your existing infrastructure to discover audit failures. As a second step, you can write Chef code that address those audit failures.

^Chef's test and repair approach helps ensure that your servers stay in compliance, and you'll have repeatable tests that you can run to prove it.

---

# [fit]After completing this workshop, you'll be able to:

- Write and apply controls, both to a local virtual machine and to a node bootstrapped to your Chef server.
- Verify and resolve audit failures.
- Use Chef Analytics to create alerts that signal when your infrastructure falls out of compliance.

^ We'll first use audit mode to discover an infrastructure change that, while appearing well-intentioned and functional, actually violates your compliance policy. Then we'll connect your audit and infrastructure code to Chef Analytics. Next we will see how audit mode can be used to discover vulnerabilities.

---

# [fit]Set up your workstation

### Everyone will get two playing cards. Match up your cards to the two IP addresses assigned to you.

# http://bit.ly/bos-int-chef

### One will be your Chef workstation, the other will be your test node. It doesn't matter which one is which; just keep track.

---

# [fit]Connect to your chef workstation

`ssh chef@10.10.10.10`

(the password is "chef.io")

---

![fit](img/georgesr.gif)
# Create a basic audit control

---

In this lesson, you'll create two cookbooks. The first cookbook implements a basic audit control that validates the ownership of web server content.

---

The second cookbook configures Apache web server and adds a few basic web pages to it. You'll use Test Kitchen to apply both cookbooks to a Ubuntu virtual machine.

---

You'll see that although the web server cookbook appears correct, it applies changes that violate your organization's compliance policy. You'll complete the lesson by fixing the violation and verifying that the system meets compliance.

---

# [fit]Create the audit cookbook
*run these commands from the home directory on your chef workstation*

`unzip chef-starter.zip`

`cd chef-repo/cookbooks`

`chef generate cookbook YOUR_INITIALS-audit-webserver`

---

# [fit]Add an audit control
Let's say that your organization's internal audit policy states that no web file can be owned by the `root` user. Let's add an audit control that tests for this.

^ There are multiple ways to organize your audit code. You can create one recipe for each platform that you manage, as is done in the audit-cis cookbook on Chef Supermarket. Alternatively, you might create one recipe for each category you need to verify – security, services, network configuration, and so on. For now, you'll add the audit code to the default recipe.

---

Add the following code to your default recipe, `default.rb`.

```ruby
control_group 'YOUR_INITIALS - web server' do
  control 'home page is not owned by root user' do
    describe file('/var/www/html/index.html') do
      it { should_not be_owned_by 'root' }
    end
  end
end
```
^ A control_group organizes related audit concerns. Here, you create a control group that validates the state of your web services. A control defines a policy to test. Here, we validate that no web file is owned by the root user.

^ Every control block breaks down into it blocks. An it block validates one part of the system by defining one or more expect statements. An expect statement verifies that a resource, such as a file or service, meets the desired state. As with many test frameworks, the code you write to implement an audit control resembles natural language.

^ The Dir class's glob method returns all files that match a given pattern. In this example, the /var/www/html/ part specifies the start of the path to match. The ** part matches all subdirectories, and * matches all files. You can think of this like the equivalent ls command, ls /var/www/html/**/*, which lists all files under /var/www/html and its subdirectories.

---

# What can you do?
### Chef audit controls are based on [Serverspec](http://serverspec.org/), which is based on [RSpec](http://rspec.info/). The [Serverspec documentation](http://serverspec.org/resource_types.html) describes the resource types you can use in your audit controls.

---

# [fit]Apply the recipe to a Test Kitchen instance
Now let's apply the audit control to a Ubuntu virtual machine. First, modify your `audit-webserver` cookbook's `.kitchen.yml` file to look like this.

---

```ruby
driver:
  name: docker
  use_sudo: false
provisioner:
  name: policyfile_zero
  client_rb:
    audit_mode: :audit_only
platforms:
  - name: ubuntu-14.04
suites:
  - name: default
    attributes:
```
^ The audit_mode: :audit_only part tells chef-client to run only your audit controls, and not apply any other resources that appear in the run-list. We specify :audit_only because this cookbook's role is only to verify your compliance policy. You can specify :enabled to apply both your configuration code and your audit controls or :disabled to run only your configuration code.

---

# Install cookbooks

Install cookbooks from a Policyfile and generate a locked cookbook set.

`chef install`

---

Run `kitchen list` to verify that the instance has not yet been created.

![inline](img/kitchen-list.png)

---

Now run `kitchen converge` to create the instance and apply your audit control.

![inline](img/kitchen-converge.png)

^ We haven't yet configured Apache or added any web files, so there are no files to test. But this is a good first step to verifying that the control is correctly set up.

---

# [fit]Create the webserver cookbook

Now let's create and apply a second cookbook that configures Apache and adds a few web pages.

First, from your `~/chef-repo` directory, create the `webserver` cookbook

`chef generate cookbook cookbooks/YOUR_INITIALS-webserver`

---

Add the following to your webserver cookbook's `recipes/default.rb`

```ruby
# Install the apache2 package.
package 'apache2' do
  action :install
end

# Enable and start the apache2 service.
service 'apache2' do
  action [:start, :enable]
end

# Add a home page to the site.
file '/var/www/html/index.html' do
  content "<h1>Hello, world!</h1>"
end
```

---

Configure the `.kitchen.yml` on the webserver cookbook

```ruby
driver:
  name: docker
  use_sudo: false
provisioner:
  name: policyfile_zero
  client_rb:
    audit_mode: :enabled
platforms:
  - name: ubuntu-14.04

suites:
  - name: default
    attributes:
```
^ don't forget the three dashes at the top

---

# Let's test out our webserver cookbook

- `chef install`
  - generate a locked set of cookbooks
- `kitchen converge`
  - see it spin up the instance
- `kitchen login`
  - login to the instance to check it out

---

Run a few commands to see if it's looking good

- `ls /var/www/html/`
- `curl http://localhost`

^ If you're the web site developer or system administrator, this configuration can look completely reasonable – it does everything you need it to do. Now let's see what happens when we audit the web server configuration.

---

# Audit your web server configuration

^ Now let's apply both the webserver and audit cookbooks to the same Test Kitchen instance.

In previous steps, you applied the audit and webserver cookbooks on separate Test Kitchen instances. Let's set things up so that you can run them both from the same instance. Here you'll apply the audit cookbook from the Test Kitchen instance for your webserver cookbook.

---

# Update the Policyfile

Edit the `Policyfile.rb` file in the `webserver` cookbook to look like this:

```ruby
name "webserver"

default_source :supermarket

run_list "YOUR_INITIALS-webserver::default", "YOUR_INITIALS-audit-webserver::default"

cookbook "YOUR_INITIALS-webserver", path: "."
cookbook "YOUR_INITIALS-audit-webserver", path: "../YOUR_INITIALS-audit-webserver"
```

---

# Edit the .kitchen.yml on your webserver cookbook

```ruby
driver:
  name: docker
  use_sudo: false
provisioner:
  name: chef_zero
  client_rb:
    audit_mode: :enabled
platforms:
  - name: ubuntu-14.04

suites:
  - name: default
    attributes:
```

^ This configuration sets the audit_mode to :enabled so that chef-client runs both the web server configuration code and the audit tests.

^ This configuration also adds the audit cookbook's default recipe to the run-list. The order is important because it ensures that the configuration changes are made before the audit tests are run.

---

# Update Policyfile.lock.json

`chef update`

---

![original fill](img/fletcher.jpg)
# [fit]KITCHEN CONVERGE!!

---

# Failure/Error!

![inline](img/failure-error.png)

^ Although the web server was successfully configured, the audit run failed. You'll see from the output that the home page caused the audit run to fail.

---

# [fit]Update your web server configuration to meet compliance

In the previous step, we saw that the home page failed the audit.

^ In practice, you would work with your team and the audit team to determine the best course of action. Here, we'll resolve these failures by creating a user named web_admin and assign that user as the owner of the web files.

---

`webserver/recipe/default.rb`

```ruby
# Install the apache2 package.
package 'apache2' do
  action :install
end

# Enable and start the apache2 service.
service 'apache2' do
  action [:start, :enable]
end

# Add a home page to the site.
file '/var/www/html/index.html' do
  content "<h1>Hello, world!</h1>"
  owner 'www-data'
  group 'www-data'
end
```

^This code creates the web_admin user and group and assigns the user as the owner of both the /var/www/html/pages directory and the web files.

---

![original fill](img/fletcher.jpg)
# [fit]KITCHEN CONVERGE AGAIN!!

---

![inline](img/audit-success.png)

---

# Get an alert when an audit run fails

Next, let's upload your `audit` and `webserver` cookbooks to Chef server, run them on a node, and see how to use Chef Analytics to alert you when your infrastructure falls out of compliance.

---

# Push your Policy to the Chef Server

From `~/chef-repo`

`knife ssl fetch`

From `~/chef-repo/cookbooks/YOUR_INITIALS-webserver`


`chef push staging`

---

# [fit]Upload your cookbooks to the Chef server

You already verified that your `audit` and `webserver` cookbooks behave as you expect on a local virtual machine, so let's begin by uploading these cookbooks to your Chef server.

Run these commands from the `chef-repo` directory.
`knife cookbook upload -a`
`rm .chef/chef-boston-validator.pem`

---

# Apply the webserver cookbook to a node
(replace YOUR\_IP\_ADDRESS with the IP address of your SECOND node)

`knife bootstrap YOUR_IP_ADDRESS
--ssh-user chef --ssh-password 'chef.io' --policy-group staging
--policy-name webserver --sudo
-N YOUR_INITIALS-node1`

---

![right](img/analytics-timeline.png)
# [fit]View the events in the Timeline view

Log into [http://bit.ly/analytics-bos-chef](http://bit.ly/analytics-bos-chef).

Once logged in, you should see something like this:

---

The nodes tab should look like this, since you had a successful run.

![inline](img/nodes.png)

---

# Add rules that trigger an alert when an audit fails

In this tutorial, instead of using a notification to respond to an event, you'll create an alert. An alert enables you to capture important events that you want to take action on, such as when an audit fails.

You access the alert history through the Chef Analytics web interface. Like a notification, an alert is raised from a rule. You can generate an alert and a notification from the same rule.

---

Recall that your control looks like this.

```ruby
control_group 'YOUR_INITIALS - web server' do
  control 'home page is not owned by root user' do
    describe file('/var/www/html/index.html') do
      it { should_not be_owned_by 'root' }
    end
  end
end
```

---

To create a rule that triggers when this audit fails, first navigate to the Chef Analytics interface from your web browser.

From the Rules tab, click + to create a new rule. From the rule editor, click `New Rule Group 1` and rename it to `YOUR_INITIALS webserver`.

---

Now add the following code to define your rule:

```ruby
rules 'YOUR_INITIALS webserver'
  rule on run control
  when
    control_group.name =~ 'YOUR_INITIALS - web server' and status != 'success'
  then
    alert:error('YOUR_INITIALS - Run control group {{message.resource_type}} {{message.resource_name}} "{{ message.name }}" failed on {{ message.run.node_name }}.')
  end
end
```

Click **Save** and you are brought back to the list of rules.

^The run_control message states a rule for a single audit. The name part of the when block corresponds to the name of the it block in your audit control. The rule triggers only when the status of the control is not success.

^The it part of your control has a different name for each file that you're testing. Therefore, we use a regular expression to match the pattern for how the it blocks are named. The =~ operator sets up the comparison as a regular expression and the user$ part says that the string to match must end with "user".

^The alert:error part adds the alert to Chef Analytics. In our case, we want the alert to signal an error condition. You can also use alert:warn and alert:info to signal other types of conditions.

---

# Run the audit cookbook

Now let's run the `audit` cookbook on your node. You already verified that the audit passes when you ran it through Test Kitchen, so let's verify that the alert doesn't trigger.

Because you already applied the `webserver` cookbook to your node, this time you'll specify the `--audit-mode audit-only` option to run only the audit code on your node.

---

Run this command - replace IP with the IP address as before
`knife ssh 'name:YOUR_INITIALS*'
'sudo chef-client
--audit-mode audit-only' --ssh-user chef --ssh-password 'chef.io'`

---

# [fit]Verify that the alert didn't trigger

You'll see from the output of your `chef-client` run that the audit tests pass. From the **Alerts** tab on the Chef Analytics web interface, verify that no alerts appear.

![inline](img/no-alerts.png)

---

# [fit]Add a new control

Specifically we want to ensure that `ntp` service is enabled and the `ntp` service is running

---

# [fit]Add an audit-ntp cookbook

`chef generate cookbook cookbooks/YOUR_INITIALS-audit-ntp`

___

Add the following to your audit-ntp cookbook's default recipe:

```ruby
control_group 'YOUR_INITIALS - ntp' do
  control 'ntp is running and enabled' do
    describe service('ntp') do
      it { should be_running }
      it { should be_enabled }
    end
  end
end
```

---

# Edit the webserver Policy to depend on your ntp cokbook

```ruby
run_list "YOUR_INITIALS-webserver::default",
"YOUR_INITIALS-audit-webserver::default",
"YOUR_INITIALS-audit-ntp::default"

cookbook "YOUR_INITIALS-webserver", path: "."
cookbook "YOUR_INITIALS-audit-webserver", path: "../YOUR_INITIALS-audit-webserver"
cookbook "YOUR_INITIALS-audit-ntp", path: "../YOUR_INITIALS-audit-ntp"

```

---

# Increment the version of the webserver cookbook

Edit the `metadata.rb` in the webserver cookbook.

Update the Policyfile.lock.json

`chef update`

---

# Test locally

Run `kitchen converge` on the webserver cookbook. It should fail 2 of 3 controls.

---

# Upload the new Policyfile and cookbooks

From the `cookbooks/YOUR_INITIALS-webserver` directory

`chef push staging`

From the chef-repo directory:

`knife cookbook upload -a`

---

# Add the Chef Analytics rules

Navigate to the Chef Analytics interface from your web browser. From the Rules tab, click + to create a new rule. From the rule editor, click `New Rule Group 1` and rename it to `YOUR_INITIALS - NTP`.

^ Now we need to add a corresponding rule to Chef Analytics that will trigger when this control fails. The process is similar to how you added the first rule.

---

Add the following code to your control

```ruby
rules 'YOUR_INITALS - Ensure NTP is active'
  rule on run_control
  when
    control_group.name =~ 'YOUR_INITIALS - NTP' and
    status != 'success'
  then
    alert:error('YOUR_INITIALS - Run control {{message.resource_type}} {{message.resource_name}} "{{ message.name }}" failed on {{ message.run.node_name }}.')
  end
end
```
---

# Run the audit and watch it fail

Run this command - replace IP with the IP address as before
`knife ssh 'name:YOUR_INITIALS*'
'sudo chef-client
--audit-mode audit-only' --ssh-user chef --ssh-password 'chef.io'`

---

# Log into the Alerts tab in Analytics and see the alert!

---

# Extra Credit

- On your chef workstation, cd into `~/cookbooks/audit-shell-shock` and run `kitchen converge`
- Add a new cookbook to remediate the node
- Write your own audit control and rule with a partner!
