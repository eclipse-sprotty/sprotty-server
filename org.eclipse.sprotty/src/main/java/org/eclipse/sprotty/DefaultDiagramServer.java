/********************************************************************************
 * Copyright (c) 2017-2018 TypeFox and others.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v. 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * This Source Code may also be made available under the following Secondary
 * Licenses when the conditions for such availability set forth in the Eclipse
 * Public License v. 2.0 are satisfied: GNU General Public License, version 2
 * with the GNU Classpath Exception which is available at
 * https://www.gnu.org/software/classpath/license.html.
 *
 * SPDX-License-Identifier: EPL-2.0 OR GPL-2.0 WITH Classpath-exception-2.0
 ********************************************************************************/
package org.eclipse.sprotty;

import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.Consumer;

import javax.inject.Inject;

import org.apache.log4j.Logger;

import com.google.common.base.Strings;

/**
 * The default diagram server implementation. It realizes the same message protocol as the
 * TypeScript class {@code LocalModelSource}.
 */
public class DefaultDiagramServer implements IDiagramServer {
	
	private static final Logger LOG = Logger.getLogger(DefaultDiagramServer.class);
	
	protected static AtomicLong nextRequestId = new AtomicLong();
	
	private String clientId;
	
	private SModelRoot currentRoot;
	
	private Map<String, String> options;
	
	private Consumer<ActionMessage> remoteEndpoint;
	
	private IModelUpdateListener modelUpdateListener;
	
	private ILayoutEngine layoutEngine;
	
	private IPopupModelFactory popupModelFactory;
	
	private IDiagramSelectionListener diagramSelectionListener;

	private IDiagramExpansionListener diagramExpansionListener;

	private IDiagramOpenListener diagramOpenListener;
	
	private boolean needsClientLayout = true;
	
	private ServerLayoutKind serverLayoutKind = ServerLayoutKind.AUTOMATIC;
	
	private final Map<String, CompletableFuture<ResponseAction>> requests = new HashMap<>();
	
	private final Set<String> expandedElements = new HashSet<>();

	private final Set<String> selectedElements = new HashSet<>();
	
	private Object modelLock = new Object();

	private int revision = 0;
	
	private ServerStatus status;
	
	private String lastSubmittedModelType;

	private SModelCloner smodelCloner;
	
	public DefaultDiagramServer() {
		currentRoot = new SModelRoot();
		currentRoot.setType("NONE");
		currentRoot.setId("ROOT");
	}
	
	public DefaultDiagramServer(String clientId) {
		this();
		this.clientId = clientId;
	}
	
	@Override
	public IDiagramState getDiagramState() {
		return new DefaultDiagramState(this);
	}

	@Override
	public String getClientId() {
		return clientId;
	}
	
	public void setClientId(String clientId) {
		this.clientId = clientId;
	}
	
	@Override
	public Consumer<ActionMessage> getRemoteEndpoint() {
		return remoteEndpoint;
	}
	
	@Override
	public void setRemoteEndpoint(Consumer<ActionMessage> remoteEndpoint) {
		this.remoteEndpoint = remoteEndpoint;
	}
	
	protected IModelUpdateListener getModelUpdateListener() {
		return modelUpdateListener;
	}
	
	@Inject
	public void setModelUpdateListener(IModelUpdateListener listener) {
		this.modelUpdateListener = listener;
	}
	
	protected ILayoutEngine getLayoutEngine() {
		return layoutEngine;
	}
	
	@Inject
	public void setLayoutEngine(ILayoutEngine engine) {
		this.layoutEngine = engine;
	}
	
	protected IPopupModelFactory getPopupModelFactory() {
		return popupModelFactory;
	}
	
	@Inject
	public void setPopupModelFactory(IPopupModelFactory factory) {
		this.popupModelFactory = factory;
	}
	
	protected IDiagramSelectionListener getSelectionListener() {
		return diagramSelectionListener;
	}
	
	@Inject
	public void setSelectionListener(IDiagramSelectionListener listener) {
		this.diagramSelectionListener = listener;
	}
	
	public IDiagramExpansionListener getExpansionListener() {
		return diagramExpansionListener;
	}
	
	@Inject
	public void setExpansionListener(IDiagramExpansionListener diagramExpansionListener) {
		this.diagramExpansionListener = diagramExpansionListener;
	}
	
	public IDiagramOpenListener getOpenListener() {
		return diagramOpenListener;
	}
	
	@Inject
	public void setOpenListener(IDiagramOpenListener diagramOpenListener) {
		this.diagramOpenListener = diagramOpenListener;
	}
	
	@Override
	public void dispatch(Action action) {
		Consumer<ActionMessage> remoteEndpoint = getRemoteEndpoint();
		if (remoteEndpoint != null) {
			remoteEndpoint.accept(new ActionMessage(getClientId(), action));
		}
	}
	
	@SuppressWarnings("unchecked")
	@Override
	public <Res extends ResponseAction> CompletableFuture<Res> request(RequestAction<Res> action) {
		if (Strings.isNullOrEmpty(action.getRequestId())) {
			action.setRequestId(generateRequestId());
		}
		CompletableFuture<Res> future = new CompletableFuture<>();
		this.requests.put(action.getRequestId(), (CompletableFuture<ResponseAction>) future);
		this.dispatch(action);
		return future;
	}
	
	/**
	 * Generate a unique {@code requestId} for a request action.
	 */
	protected String generateRequestId() {
	    return "server_" + nextRequestId.incrementAndGet();
	}
	
	@Override
	public SModelRoot getModel() {
		return currentRoot;
	}
	
	@Override
	public CompletableFuture<Void> setModel(SModelRoot newRoot) {
		if (newRoot == null)
			throw new NullPointerException();
		synchronized(modelLock) {
			newRoot.setRevision(++revision);
			currentRoot = newRoot;
		}
		return submitModel(newRoot, false, null);
	}
	
	@Override
	public CompletableFuture<Void> updateModel(SModelRoot newRoot) {
		if (newRoot == null)
			throw new IllegalArgumentException("updateModel() cannot be called with null");
		synchronized(modelLock) {
			if (getServerLayoutKind(newRoot) == ServerLayoutKind.AUTOMATIC) {
				LayoutUtil.copyLayoutData(currentRoot, newRoot);
			}
			currentRoot = newRoot;
			newRoot.setRevision(++revision);
		}
		return submitModel(newRoot, true, null);
	}
	
	public ServerStatus getStatus() {
		return status;
	}
	
	public void setStatus(ServerStatus status) {
		this.status = status;
		dispatch(new ServerStatusAction(status));
	}
	
	@Override
	public Map<String, String> getOptions() {
		if (options == null) {
			options = new LinkedHashMap<>();
		}
		return options;
	}
	
	protected void setOptions(Map<String, String> options) {
		this.options = new LinkedHashMap<>(options);
	}
	
	/**
	 * Whether the client needs to compute the layout of parts of the model. This affects the behavior or
	 * {@link #submitModel(SModelRoot, boolean)}.
	 * 
	 * <p>The default implementation returns the value configured with {@link #setNeedsClientLayout(boolean)},
	 * but this can be overridden to determine the value depending on the given model. The initial value
	 * is {@code true}.</p>
	 */
	protected boolean needsClientLayout(SModelRoot root) {
		return needsClientLayout;
	}
	
	public void setNeedsClientLayout(boolean value) {
		this.needsClientLayout = value;
	}
	
	/**
	 * Whether and when the server needs to compute the layout of parts of the model. The layout is computed
	 * with the layout engine configured with {@link #setLayoutEngine(ILayoutEngine)}, so returning {@code true}
	 * here makes sense only if such an engine is available.
	 *
	 * <p>The default implementation returns the value configured with {@link #setServerLayoutKind(ServerLayoutKind)},
	 * but this can be overridden to determine the value depending on the given model. The initial value
	 * is {@code false}.</p>
	 */
	protected ServerLayoutKind getServerLayoutKind(SModelRoot root) {
		return this.serverLayoutKind;
	}
	
	public void setServerLayoutKind(ServerLayoutKind value) {
		this.serverLayoutKind = value;
	}
	
	/**
	 * Submit a new or updated model to the client. If client layout is required, a {@link RequestBoundsAction}
	 * is sent, otherwise either a {@link SetModelAction} or an {@link UpdateModelAction} is sent depending on
	 * the {@code update} parameter.
	 */
	protected CompletableFuture<Void> submitModel(SModelRoot newRoot, boolean update, Action cause) {
		if (needsClientLayout(newRoot)) {
			if (getServerLayoutKind(newRoot) == ServerLayoutKind.NONE) {
				// In this case the client won't send us the computed bounds
				dispatch(new RequestBoundsAction(newRoot));
				IModelUpdateListener listener = getModelUpdateListener();
				if (listener != null)
					listener.modelSubmitted(newRoot, this);
			} else {
				return request(new RequestBoundsAction(newRoot)).handle((response, exception) -> {
					if (exception != null) {
						LOG.error(exception);
					} else {
						SModelRoot model = handle(response);
						if (model != null)
							doSubmitModel(model, true, cause);
					}
					return null;
				});
			}
		} else {
			doSubmitModel(newRoot, update, cause);
		}
		return CompletableFuture.completedFuture(null);
	}
	
	private void doSubmitModel(SModelRoot newRoot, boolean update, Action cause) {
		ServerLayoutKind layoutKind = getServerLayoutKind(newRoot);
		if (layoutKind == ServerLayoutKind.AUTOMATIC 
				|| layoutKind == ServerLayoutKind.INTERACTIVE) {
			ILayoutEngine layoutEngine = getLayoutEngine();
			if (layoutEngine != null) {
				layoutEngine.layout(newRoot, cause);
			}
		}
		synchronized (modelLock) {
			if (newRoot.getRevision() == revision) {
				String modelType = newRoot.getType();
				if (cause instanceof RequestModelAction
						&& !Strings.isNullOrEmpty(((RequestModelAction) cause).getRequestId())) {
					RequestModelAction request = (RequestModelAction) cause;
					SetModelAction response = new SetModelAction(newRoot);
					response.setResponseId(request.getRequestId());
		            dispatch(response);
		        } else if (update && modelType != null && modelType.equals(lastSubmittedModelType)) {
					dispatch(new UpdateModelAction(newRoot));
				} else {
					dispatch(new SetModelAction(newRoot));
				}
				lastSubmittedModelType = modelType;
				IModelUpdateListener listener = getModelUpdateListener();
				if (listener != null) {
					listener.modelSubmitted(newRoot, this);
				}
			}
		}
	}
	
	@Override
	public void accept(ActionMessage message) {
		String clientId = message.getClientId();
		if (clientId == null || clientId.equals(this.getClientId())) {
			Action action = message.getAction();
			if (action instanceof ResponseAction) {
				ResponseAction response = (ResponseAction) action;
				String id = response.getResponseId();
				if (!Strings.isNullOrEmpty(id)) {
					CompletableFuture<ResponseAction> future = requests.get(id);
		            if (future != null) {
		                this.requests.remove(id);
		                future.complete(response);
		                return;
		            }
		            if (LOG.isInfoEnabled()) {
		            	LOG.info("No matching request for response:\n" + action);
		            }
				}
	        }
			handleAction(action);
		}
	}

	protected void handleAction(Action action) {
		switch (action.getKind()) {
			case RequestModelAction.KIND:
				handle((RequestModelAction) action);
				break;
			case RequestPopupModelAction.KIND:
				handle((RequestPopupModelAction) action);
				break;
			case ComputedBoundsAction.KIND:
				handle((ComputedBoundsAction) action);
				break;
			case SelectAction.KIND:
				handle((SelectAction) action);
				break;
			case SelectAllAction.KIND:
				handle((SelectAllAction) action);
				break;
			case CollapseExpandAction.KIND:
				handle((CollapseExpandAction) action);
				break;
			case CollapseExpandAllAction.KIND:
				handle((CollapseExpandAllAction) action);
				break;
			case OpenAction.KIND:
				handle((OpenAction) action);
				break;
			case LayoutAction.KIND:
				handle((LayoutAction) action);
				break;
		}
	}
	
	/**
	 * Called when a {@link RequestModelAction} is received.
	 */
	protected void handle(RequestModelAction request) {
		Map<String, String> options = request.getOptions();
		if (options != null) {
			setOptions(options);
			String needsClientLayout = options.get("needsClientLayout");
			if (needsClientLayout != null && !needsClientLayout.isEmpty())
				setNeedsClientLayout(Boolean.parseBoolean(needsClientLayout));
		}
		submitModel(getModel(), false, request);
	}
	
	/**
	 * Called when a {@link ComputedBoundsAction} is received.
	 */
	protected SModelRoot handle(ComputedBoundsAction computedBounds) {
		synchronized(modelLock) {
			SModelRoot model = getModel();
			if (model.getRevision() == computedBounds.getRevision()) {
				LayoutUtil.applyBounds(model, computedBounds);
				return model;
			}
		}
		return null;
	}
	
	/**
	 * Called when a {@link RequestPopupModelAction} is received.
	 */
	protected void handle(RequestPopupModelAction request) {
		SModelRoot model = getModel();
		SModelElement element = SModelIndex.find(model, request.getElementId());
		IPopupModelFactory factory = getPopupModelFactory();
		if (factory != null) {
			SModelRoot popupModel = factory.createPopupModel(element, request, this);
			if (popupModel != null) {
				SetPopupModelAction response = new SetPopupModelAction(popupModel);
				response.setResponseId(request.getRequestId());
				dispatch(response);
			}
		}
	}
	
	/**
	 * Called when a {@link SelectAction} is received.
	 */
	protected void handle(SelectAction action) {
			selectedElements.clear();
		if (action.getDeselectedElementsIDs() != null)
			selectedElements.removeAll(action.getDeselectedElementsIDs());
		if (action.getSelectedElementsIDs() != null)
			selectedElements.addAll(action.getSelectedElementsIDs());

		IDiagramSelectionListener selectionListener = getSelectionListener();
		if (selectionListener != null) {
			selectionListener.selectionChanged(action, this);
		}
	}
	
	/**
	 * Called when a {@link SelectAllAction} is received.
	 */
	protected void handle(SelectAllAction action) {
		if (action.isSelect())
			new SModelIndex(getModel()).allIds().forEach(id -> selectedElements.add(id));
		else
			selectedElements.clear();
		
		IDiagramSelectionListener selectionListener = getSelectionListener();
		if (selectionListener != null) {
			selectionListener.selectionChanged(action, this);
		}
	}
	
	/**
	 * Called when a {@link CollapseExpandAction} is received.
	 */
	protected void handle(CollapseExpandAction action) {
		if (action.getCollapseIds() != null)
			expandedElements.removeAll(action.getCollapseIds());
		if (action.getExpandIds() != null)
			expandedElements.addAll(action.getExpandIds());
		
		IDiagramExpansionListener expansionListener = getExpansionListener();
		if (expansionListener != null) {
			expansionListener.expansionChanged(action, this);
		}
	}
	
	/**
	 * Called when a {@link CollapseExpandAllAction} is received.
	 */
	protected void handle(CollapseExpandAllAction action) {
		if (action.isExpand())
			new SModelIndex(getModel()).allIds().forEach(id -> expandedElements.add(id));
		else
			expandedElements.clear();
		
		IDiagramExpansionListener expansionListener = getExpansionListener();
		if (expansionListener != null) {
			expansionListener.expansionChanged(action, this);
		}
	}
	
	/**
	 * Called when a {@link OpenAction} is received.
	 */
	protected void handle(OpenAction action) {
		IDiagramOpenListener openListener = getOpenListener();
		if (openListener != null) {
			openListener.elementOpened(action, this);
		}
	}
	
	/**
	 * Called when a {@link LayoutAction} is received.
	 */
	protected void handle(LayoutAction action) {
		ServerLayoutKind layoutKind = getServerLayoutKind(currentRoot);
		if (layoutKind != ServerLayoutKind.NONE) {
			ILayoutEngine layoutEngine = getLayoutEngine();
			if (layoutEngine != null) {
				// Clone the current model, as it has already been sent to the client with the old revision
				SModelCloner cloner = getSModelCloner();
				SModelRoot newRoot = cloner.clone(getModel());
				synchronized(modelLock) {
					newRoot.setRevision(++revision);
					currentRoot = newRoot;
				}
				// Don't execute layout twice
				if (getServerLayoutKind(newRoot) != ServerLayoutKind.AUTOMATIC) {
					layoutEngine.layout(newRoot, action);
				}
				doSubmitModel(newRoot, true, action);
			}
		}
	}
	
	@Inject 
	protected void setSModelCloner(SModelCloner smodelCloner) {
		this.smodelCloner = smodelCloner;
	}
	
	protected SModelCloner getSModelCloner() {
		return this.smodelCloner;	
	}
	
	public static class DefaultDiagramState implements IDiagramState {

		private DefaultDiagramServer server;

		DefaultDiagramState(DefaultDiagramServer server) {
			this.server = server;
		}
		
		@Override
		public Map<String, String> getOptions() {
			return server.options;
		}
		
		@Override
		public String getClientId() {
			return server.clientId;
		}
		
		@Override
		public SModelRoot getCurrentModel() {
			return server.currentRoot;
		}
		
		@Override
		public Set<String> getExpandedElements() {
			return server.expandedElements;
		}
		
		@Override
		public Set<String> getSelectedElements() {
			return server.selectedElements;
		}
	}
}
