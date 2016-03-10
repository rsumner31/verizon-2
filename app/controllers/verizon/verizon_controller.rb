class Verizon::VerizonController < ApplicationController
	skip_before_filter :verify_authenticity_token  

	# Allow mass assignment, we are just translating calls
	ActionController::Parameters.permit_all_parameters = true

	# Report the soap errors in json format
	rescue_from Savon::SOAP::Fault, :with => :reportError
	
	# Declaration for wsdl path
	@@wsdl = ''
	# Certificate information
	@@cert 	= ENV['verizon_cert']
	@@key 	= ENV['verizon_key']
	# authentication information
	@@username = ENV['verizon_username']
	@@password = ENV['verizon_password']

	# Access the inventory WSDL
	def inventory
		call('Wholesale_VOIP_TN_Inventory_v3r0?wsdl')
	end

	def orders
		call('Wholesale_VOIP_Ebonding_Ordering_v3r0?wsdl')
	end

	def csr
		call('VOIP_CSR_Query_v5r0?wsdl')
	end

	def porting
		call('VOIP_TN_PortActivation_v1r1?wsdl')
	end

	def lnp
		call('LNPPreQualService_v1r0?wsdl')
	end

	# prepares the SOAP request object and returns the response
	private
	def call(wsdl)
		@@wsdl = ENV['verizon_url'] + wsdl
		if(params[:function])
			response = client.request params[:function] do 
				soap.body = getBody
			end
		else
			response = client.wsdl.soap_actions
			response.map! { |v| v.to_s.camelize(:lower) }
			response = {:availableFunctions => response}
		end
		logger.info response.inspect
		render :json => response.to_json
	end

	# Returns the structured body, removing unnecessary parameters
	private 
	def getBody
		body = params
		# Removing unncessary items
		body.delete :controller
		body.delete :action
		body.delete :function

		
		# return as a hash
		body.to_h
	end

	# Prepares the soap client for requests
	private 
	def client
		Savon.configure do |config|
			config.log = true
			config.logger = Rails.logger
		end

		Savon.client do |wsdl,http,wsse|
			# binding.pry
			wsdl.document = @@wsdl
			wsse.sign_with = Akami::WSSE::Signature.new(
				Akami::WSSE::Certs.new :cert_file => @@cert, :private_key_file => @@key
				)
			wsse['Security']['UsernameToken'] = {'Username' => @@username, 'Password' => @@password}
		end
	end

	# Reports exceptions in json format.
	private 
	def reportError(error)
		render :json => {:error => error.to_s}.to_json, :status => 500
	end

end
