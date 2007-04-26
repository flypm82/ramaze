#          Copyright (c) 2006 Michael Fellinger m.fellinger@gmail.com
# All files in this distribution are subject to the terms of the Ruby license.

require 'spec/helper'

testcase_requires 'ramaze/template/haml'

class TCTemplateHamlController < Ramaze::Controller
  trait :template_root => 'spec/ramaze/template/haml/'
  trait :engine => Ramaze::Template::Haml

  helper :link

  def index
  end

  def with_vars
    @title = "Teen Wolf"
  end
end

context "Simply calling" do
  ramaze(:mapping => {'/' => TCTemplateHamlController})

  specify "index" do
    get('/').should ==
"<div id='contact'>
  <h1>Eugene Mumbai</h1>
  <ul class='info'>
    <li class='login'>eugene</li>
    <li class='email'>eugene@example.com</li>
  </ul>
</div>"
  end

  specify "variables in controller" do
    get('/with_vars').should ==
%{<div id='content'>
  <div class='title'>
    <h1>Teen Wolf</h1>
    <a href="Home">Home</a>
  </div>
</div>}
  end
end